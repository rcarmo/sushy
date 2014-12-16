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
    title       = CharField()
    tags        = CharField() 
    hash        = CharField() # plaintext hash, used for etags
    mtime       = DateTimeField()

    class Meta:
        database = db


class Link(Model):
    """Links between pages - doesn't use ForeignKeys since pages may not exist"""
    page = CharField(unique=False, index=True)
    link = CharField(unique=False, index=True)

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
    try:
        Page.create_table()
        Link.create_table()
        FTSPage.create_table()
    except OperationalError as e:
        log.info(e)


def add_wiki_link(**kwargs):
    with db.transaction():
        link = Link.create(**kwargs)


def del_wiki_page(page):
    with db.transaction():
        page = Page.get(Page.name == page)
        FTSPage.delete().where(FTSPage.page == page).execute()
        Page.delete().where(Page.name == page).execute()
        Link.delete().where(Link.page == page).execute()


def add_wiki_page(**kwargs):
    with db.transaction():
        try:
            page = Page.create(**kwargs)
        except IntegrityError:
            page = Page.get(Page.name == kwargs["name"])
        content = []
        for k in ['title', 'body', 'tags']:
            if kwargs[k]:
                content.append(kwargs[k])
            # Not too happy about this, but FTS update() seems to be buggy 
            FTSPage.delete().where(FTSPage.page == page).execute()
            FTSPage.create(page = page, content = '\n'.join(content))


def get_wiki_page(id):
    return Page.get(Page.id == id)._data


def get_latest(limit=20, months_ago=3):
    query = (Page.select()
                .where(Page.mtime >= (datetime.datetime.now() + datetime.timedelta(months=-months_ago)))
                .order_by(SQL('mtime').desc())
                .limit(limit)
                .dicts())

    for page in query:
        yield page


def search(qstring, limit=50):
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