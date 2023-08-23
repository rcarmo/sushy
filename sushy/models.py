import re, sys, logging
from bottle import hook
from os import environ
import datetime
from dateutil.relativedelta import relativedelta
from difflib import SequenceMatcher
from peewee import *
from playhouse.sqlite_ext import *
from os.path import basename

log = logging.getLogger(__name__)

# Database models for metadata caching and full text indexing using SQLite3 
# (handily beats Whoosh and makes for a single index file)

db = SqliteExtDatabase(environ['DATABASE_PATH'])

class Page(Model):
    """Page information"""
    name        = FixedCharField(primary_key=True, max_length=128)
    title       = FixedCharField(null=True, index=True, max_length=128)
    tags        = FixedCharField(null=True, index=True, max_length=256)
    hash        = FixedCharField(null=True, index=True, max_length=64) # 40-char plaintext hash, used for etags
    mtime       = DateTimeField(index=True) # UTC
    pubtime     = DateTimeField(index=True) # UTC
    idxtime     = IntegerField(index=True) # epoch
    readtime    = IntegerField(null=True) # seconds

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
    """Full text indexing"""
    page = ForeignKeyField(Page, index=True)
    title = TextField()
    tags = TextField()
    body = TextField()

    class Meta:
        database = db
        extension_options = {'tokenize': 'porter'}


def init_db():
    """Initialize the database"""
    db.execute_sql('PRAGMA journal_mode=WAL')
    try:
        Page.create_table()
        Link.create_table()
        FTSPage.create_table()
    except OperationalError as e:
        log.info(e)


def add_wiki_links(links):
    """Adds a set of wiki links"""
    with db.atomic(): # deferring transactions gives us a nice speed boost
        for l in links:
            try:
                return Link.create(**l)
            except IntegrityError as e:
                log.debug(e) # skip duplicate links


def delete_wiki_page(page):
    """Deletes all the entries for a page"""
    with db.atomic():
        try:
            FTSPage.delete().where(FTSPage.page == page).execute()
            Page.delete().where(Page.name == page).execute()
            Link.delete().where(Link.page == page).execute()
        except Exception as e:
            log.warn(e)


def index_wiki_page(**kwargs):
    """Adds wiki page metatada and FTS data."""
    with db.atomic():
        values = {}
        for k in [u"name", u"title", u"tags", u"hash", u"mtime", u"pubtime", u"idxtime", u"readtime"]:
            values[k] = kwargs[k]
        log.debug(values)
        try:
            page = Page.create(**values)
        except IntegrityError:
            page = Page.get(Page.name == values['name'])
            page.update(**values)
        if len(kwargs['body']):
            values['body'] = kwargs['body']
            # Not too happy about this, but FTS update() seems to be buggy and indexes keep growing
            FTSPage.delete().where(FTSPage.page == page).execute()
            FTSPage.create(page = page, **values)
        return page


def get_page_metadata(name):
    """accessor for page metadata"""
    try:
        return Page.get(Page.name == name)._data
    except Exception as e:
        log.warn(e)
        return None


def get_links(page_name):
    """Backlinks (links to current page)"""
    try:
        query = (Page.select()
                    .join(Link, on=(Link.page == Page.name))
                    .where((Link.link == page_name))
                    .order_by(SQL('mtime').desc())
                    .dicts())

        for page in query:
            yield page

        # Links from current page to valid pages
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


def get_page_indexing_time(name):
    """Check when a page was last indexed"""
    try:
        return Page.get(Page.name == name).idxtime
    except Exception as e:
        return None


def get_last_update_time():
    """Check when a page was last updated by the user"""
    query = (Page.select()
            .order_by(SQL('mtime').desc())
            .limit(1)
            .dicts())
    for page in query:
        return page["mtime"]


def get_latest(limit=20, since=None, regexp=None):
    """Get the latest pages by modification time"""
    if regexp:
        if since:
            query = (Page.select()
                    .where(Page.name.regexp(regexp.pattern) and Page.mtime > since)
                    .order_by(SQL('mtime').desc())
                    .limit(limit)
                    .dicts())
        else:
            query = (Page.select()
                    .where(Page.name.regexp(regexp.pattern))
                    .order_by(SQL('mtime').desc())
                    .limit(limit)
                    .dicts())
    else:
        if since:
            query = (Page.select()
                    .where(Page.mtime > since)
                    .order_by(SQL('mtime').desc())
                    .limit(limit)
                    .dicts())
        else:
            query = (Page.select()
                    .order_by(SQL('mtime').desc())
                    .limit(limit)
                    .dicts())

    for page in query:
        yield page


def get_all():
    """Get ALL the pages"""
    query = (Page.select()
            .order_by(SQL('mtime').desc())
            .dicts())

    for page in query:
        yield page


def search(qstring, limit=50):
    """Full text search"""
    query = (FTSPage.select(Page,
                            FTSPage,
                            fn.snippet(FTSPage.as_entity()).alias('extract'),
                            FTSPage.bm25().alias('score'))
                    .join(Page)
                    .where(FTSPage.match(qstring))
                    .order_by(SQL('score').asc())
                    #.order_by(Page.mtime.desc())
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


def get_prev_by_name(name):
    """Get the previous page by page name"""
    query = (Page.select(Page.name, Page.title)
            .where(Page.name < name)
            .order_by(Page.name.desc())
            .limit(1)
            .dicts())
    for p in query:
        return p


def get_next_by_name(name):
    """Get the next page by page name"""
    query = (Page.select(Page.name, Page.title)
            .where(Page.name > name)
            .order_by(Page.name.asc())
            .limit(1)
            .dicts())
    for p in query:
        return p


def get_prev_by_date(name, regexp):
    """Get the previous page by page publishing date"""
    p = Page.get(Page.name == name)
    query = (Page.select(Page.name, Page.title)
            .where(Page.pubtime < p.pubtime)
            .order_by(Page.pubtime.desc())
            .dicts())
    for p in filter(lambda x: regexp.match(x['name']), query):
        return p


def get_next_by_date(name, regexp):
    """Get the next page by page publishing date"""
    p = Page.get(Page.name == name)
    query = (Page.select(Page.name, Page.title)
            .where(Page.pubtime > p.pubtime)
            .order_by(Page.pubtime.asc())
            .dicts())
    for p in filter(lambda x: regexp.match(x['name']), query):
        return p
            

def get_prev_next(name, regexp = None):
    """Get the previous/next page depending on a pattern"""
    try:
        if regexp:
            p, n = get_prev_by_date(name, regexp), get_next_by_date(name, regexp)
        else:
            p, n = get_prev_by_name(name), get_next_by_name(name)
        return p, n
    except Exception as e:
        log.warn(e)
        return None, None


def get_table_stats():
    """Database stats"""
    return {
        "pages": Page.select().count(),
        "links": Link.select().count(),
        "fts": FTSPage.select().count()
    }


@hook('before_request')
def _connect_db():
    db.connect()


@hook('after_request')
def _close_db():
    if not db.is_closed():
        db.close()
