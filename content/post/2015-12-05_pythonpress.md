---
date: 2012-12-02T22:27:13+01:00
title: PythonPress
---
Da eine neue Sprache nicht genug ist, beschäftige ich mich neben Ruby neuerdings auch noch mit Python.

Als Lernprojekt setze ich aktuell CodrPress als Python-Version um. Natürlich will ich das nicht das Rad neu erfinden, daher setze ich auf zwei Frameworks, dank denen ich sehr schnell ein vorzeigbares Ergebnis zusammenbauen konnte:

- [Flask](http://flask.pocoo.org/) ist ein Micro-Framework vergleichbar mit Sinatra (Ruby) oder Silex (PHP). Es kümmert sich also um alles, was man braucht, um eine Website zu bauen. Vom Routing bis hin zur Template Engine (Jinja2).

- [MongoEngine](http://mongoengine.org/) bietet einen ODM (Object Document Mapper) vergleichbar mit Mongoid (Ruby) oder meinem eigenen Projekt MongoAppKit in PHP.

## Routen-Definitionen mit Flask

~~~ python
from flask import Flask

app = Flask(__name__)

@app.route('/hello/<name>')
def hello(name):
    return 'Hello %s!' % name

app.run()
~~~

Zu Beginn wird die Klasse `Flask` aus dem Package `flask` importiert und anschließend eine Instanz erstellt.

Im Gegensatz zu PHP oder anderen C-Syntax-Sprachen kennt Python das Schlüsselwort new nicht. Um ein neues Objekt zu instanziieren reicht es den Klassennamen samt den Klammern und ggf. den Constructor-Argumenten zu schreiben.

Es folgt die Routen-Definition. Variable Werte werden in spitze Klammern gesetzt und der anschließenden Methode mit gleichem Namen als Parameter übergeben.

Wie auch in Silex oder Sinatra wird der Rückgabewert einer Routen-Methode zurück an den Browser geschickt. In diesem Fall ist das nur ein simpler String-Wert.

## Templates in Flask

Flask nutzt die Template Engine Jinja2. Wer aus der PHP-Welt Twig kennt fühlt sich sofort heimisch. Die Sprachelemente sind nahezu identisch.

Datei: `./templates/hello.html`

~~~ html
<h1>Hello {{ name }}!</h1>  
~~~

In obiger Route müsste die Methode nun so aussehen:

~~~ python
from flask import Flask, render_template
...
def hello(name):
    return render_template('hello.html', name = name)
...
~~~

Nicht vergessen: `render_template` muss zusätzlich importiert werden!

## MongoEngine

~~~ python
from mongoengine import *

connect('test')

class Post(Document):
    _id = ObjectIdField()
    created_at = DateTimeField()
    published = BooleanField()
    title = StringField()
    body = StringField()
~~~

Der Aufruf von `connect` stellt eine Verbindung zur Datenbank `test` her. Da keine Verbindungsdaten angegeben werden, geht MongoEngine automatisch von einem lokalen MongoDB-Server auf dem Standard-Port aus.

Die Klasse `Post` ist eine Sub-Klasse von `Document` aus MongoEngine. Anschließend werden die Felder der Klasse definiert. MongoEngine stellt für jeden von MongoDB unterstützten Datentyp entsprechende Klassen zur Verfügung.

Sofern nicht über das Attribut `meta` eine andere Collection definiert wird, greift MongoEngine auf den Klassennamen in Kleinbuchstaben als Collection zu.

Um ein neues Dokument von Post zu erstellen und zu speichern, reicht schon folgender Code:

~~~ python
post = Post()
post.published = True
post.title = 'Hello World!'
post.body = 'Hallo, ich ein Test.'
post.save()
~~~

## Abfragen mit MongoEngine

Als vollständiger ODM bietet MongoEngine natürlich auch die Möglichkeit vorhandene Daten abzufragen. In folgendem Beispiel werden die letzten zehn veröffentlichten Einträge absteigend nach der Erstelldatum sortiert, in ein Array geschrieben.

~~~ python
posts = Post.objects(published = True).order_by('-created_at').limit(10)
~~~

Abfragen erfolgen statisch, daher ist keine Instanz nötig. Die Methode `objects()` enthält die Bedingungen, also in diesem Fall, dass ein Eintrag veröffentlicht wurde. `order_by()` erwartet den Feldnamen mit der Sortierrichtung als Präfix. Hierbei steht `+` für aufsteigend und `-` für absteigend. Zu guter letzt wird das Ergebnis mit `limit()` auf 10 Dokumente eingeschränkt.

Mit diesem Wissen lässt sich nun ganz schnell eine Basis-Applikation bauen, die aus der vorhandenen CodrPress-Collection Einträge ausliest und anzeigt.

Der bisherige Stand ist natürlich bei [GitHub](https://github.com/MadCatme/CodrPressP).
