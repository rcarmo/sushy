import os, sys, logging
from peewee import *
from playhouse.sqlite_ext import *
from playhouse.kv import PickledKeyStore
import datetime
from dateutil.relativedelta import relativedelta

log = logging.getLogger(__name__)

# Database models for metadata caching and full text indexing using SQLite3 (handily beats Whoosh and makes for a single index file)

# TODO: port these to Hy (if at all possible given that Peewee relies on inner classes)

db = SqliteExtDatabase(os.environ['DATABASE_PATH'], threadlocals=True)

KVS = PickledKeyStore(ordered=True, database=db)

class Page(Model):
    """Metadata table"""
    name        = CharField(primary_key=True)
    title       = CharField(null=True, index=True)
    tags        = CharField(null=True, index=True)
    hash        = CharField(null=True, index=True) # plaintext hash, used for etags
    mtime       = DateTimeField(index=True) # UTC
    pubtime     = DateTimeField(index=True) # UTC

    class Meta:
        database = db


class Link(Model):
    """Links between pages - doesn't use ForeignKeys since pages may not exist"""
    page = CharField()
    link = CharField()

    class Meta:
        indexes = (
            (('page', 'link'), True),
        )
        database = db


class FTSPage(FTSModel):
    """Full text indexing table"""
    page = ForeignKeyField(Page, primary_key=True)
    content = TextField()

    class Meta:
        database = db


def init_db():
    """Initialize the database"""
    db.execute_sql('PRAGMA journal_mode=WAL')
    try:
        Page.create_table()
        Link.create_table()
        FTSPage.create_table()
    except OperationalError as e:
        log.info(e)


def add_wiki_link(**kwargs):
    """Adds a wiki link"""
    with db.transaction(): # deferring transactions gives us a nice speed boost
        try:
            return Link.create(**kwargs)
        except IntegrityError as e:
            log.debug(e) # skip duplicate links


def del_wiki_page(page):
    with db.transaction():
        page = Page.get(Page.name == page)
        FTSPage.delete().where(FTSPage.page == page).execute()
        Page.delete().where(Page.name == page).execute()
        Link.delete().where(Link.page == page).execute()


def index_wiki_page(**kwargs):
    """Adds wiki page metatada and FTS data."""
    with db.transaction():
        values = {}
        for k in [u"name", u"title", u"tags", u"hash", u"mtime", u"pubtime"]:
            values[k] = kwargs[k]
        log.debug(values)
        try:
            page = Page.create(**values)
        except IntegrityError:
            page = Page.get(Page.name == values["name"])
            page.update(**values)
        if len(kwargs['body']):
            parts = []
            for k in ['title', 'body', 'tags']:
                if kwargs[k]:
                    parts.append(kwargs[k])
            content = '\n'.join(parts)
            # Not too happy about this, but FTS update() seems to be buggy and indexes keep growing
            FTSPage.delete().where(FTSPage.page == page).execute()
            FTSPage.create(page = page, content = content)
        return page


def get_metadata(name):
    try:
        with db.transaction():
            return Page.get(Page.name == name)._data
    except Exception as e:
        log.warn(e)
        return None


def get_links(page_name):
    # Backlinks (links to current page)
    try:
        with db.transaction():
            query = (Page.select()
                     .join(Link, on=(Link.page == Page.name))
                     .where((Link.link == page_name))
                     .order_by(SQL('mtime').desc())
                     .dicts())

            for page in query:
                yield page

        # Links from current page to valid pages
        with db.transaction():
            query = (Page.select()
                     .join(Link, on=(Link.link == Page.name))
                     .where((Link.page == page_name))
                     .order_by(SQL('mtime').desc())
                     .dicts())

            for page in query:
                yield page
    except OperationalError as e:
        log.warn(e)
        return        


def get_latest(limit=20, months_ago=6):
    with db.transaction():
        query = (Page.select()
                .where(Page.mtime >= (datetime.datetime.now() + relativedelta(months=-months_ago)))
                .order_by(SQL('mtime').desc())
                .limit(limit)
                .dicts())

        for page in query:
            yield page


def get_all():
    with db.transaction():
        query = (Page.select()
                .order_by(SQL('mtime').desc())
                .dicts())

        for page in query:
            yield page


def search(qstring, limit=50):
    with db.transaction():
        query = (FTSPage.select(Page,
                             FTSPage,
                             # this is not supported yet: FTSPage.snippet(FTSPage.content).alias('extract'),
                             # so we hand-craft the SQL for it
                             SQL('snippet(ftspage) as extract'),
                             FTSPage.bm25(FTSPage.content).alias('score'))
                     .join(Page)
                     .where(FTSPage.match(qstring))
                     .order_by(SQL('score').desc())
                     .limit(limit))

        for page in query:
            yield {
                "content"     : page.extract,
                "title"       : page.page.title,
                "score"       : round(page.score, 2),
                "mtime"       : page.page.mtime,
                "tags"        : page.page.tags,
                "name"        : page.page.name
            }


@db.func()
def levenshtein(a,b):
    """Computes the Levenshtein distance between a and b."""
    n, m = len(a), len(b)
    if n > m:
        # Make sure n <= m, to use O(min(n,m)) space
        a,b = b,a
        n,m = m,n
        
    current = range(n+1)
    for i in range(1,m+1):
        previous, current = current, [i]+[0]*n
        for j in range(1,n+1):
            add, delete = previous[j]+1, current[j-1]+1
            change = previous[j-1]
            if a[j-1] != b[i-1]:
                change = change + 1
            current[j] = min(add, delete, change)
    return current[n]


def get_closest_matches(name):
    with db.transaction():
        query = (Page.select()
                .order_by(fn.levenshtein(name, Page.name).asc())
                .dicts())

        for page in query:
            yield page