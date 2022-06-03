FROM python:3.7.13-alpine

ADD app.py app.py
ADD requirements.txt requirements.txt
ADD wsgi.py wsgi.py
ADD __init__.py __init__.py
ADD EssentialSQL.db EssentialSQL.db

RUN pip install -r requirements.txt
EXPOSE 5002

CMD gunicorn --worker-class gevent --workers 1 --bind 0.0.0.0:5002 wsgi:app --timeout 5 --keep-alive 5 --log-level info