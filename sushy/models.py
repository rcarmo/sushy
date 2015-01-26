import os, sys, logging
from peewee import *
from playhouse.sqlite_ext import *
import datetime

log = logging.getLogger()

# Database models for metadata caching and full text indexing using SQLite3 (handily beats Whoosh and makes for a single index file)

# TODO: port these to Hy (if at all possible given that Peewee relies on inner classes)

db = SqliteExtDatabase(os.environ['DATABASE_PATH'], threadlocals=True)

class Page(Model):
    """Metadata table"""
    name        = CharField(primary_key=True)
    title       = CharField(null=True, index=True)
    tags        = CharField(null=True, index=True)
    hash        = CharField(null=True, index=True) # plaintext hash, used for etags
    mtime       = DateTimeField(index=True)
    pubtime     = DateTimeField(index=True)

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
        
        
class Cache(Model):
    """Key-value store for arbitrary data"""
    key   = CharField(primary_key=True)
    value = BlobField(null=True)
    
    class Meta:
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
        Cache.create_table()
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
        log.debug(kwargs)
        try:
            page = Page.create(**kwargs)
        except IntegrityError:
            page = Page.get(Page.name == kwargs["name"])
        values = {}
        for k in [u"title", u"tags", u"hash", u"mtime", u"pubtime"]:
            values[k] = kwargs[k]
        log.debug(values)
        q = page.update(**values)
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


def get_wiki_page(id):
    with db.transaction():
        return Page.get(Page.id == id)._data


def get_links(page_name):
    with db.transaction():
        query = (Page.select()
                 .join(Link, on=(Link.page == Page.name))
                 .where((Link.link == page_name))
                 .order_by(SQL('mtime').desc())
                 .dicts())

        for page in query:
             yield page

    with db.transaction():
        query = (Page.select()
                 .join(Link, on=(Link.link == Page.name))
                 .where((Link.page == page_name))
                 .order_by(SQL('mtime').desc())
                 .dicts())

        for page in query:
             yield page


def get_latest(limit=20, months_ago=3):
    with db.transaction():
        query = (Page.select()
                .where(Page.mtime >= (datetime.datetime.now() + datetime.timedelta(months=-months_ago)))
                .order_by(SQL('mtime').desc())
                .limit(limit)
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
