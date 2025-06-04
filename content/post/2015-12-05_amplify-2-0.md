---
date: 2013-07-27T22:30:36+01:00
title: Amplify 2.0
---
Ich habe Amplify grundlegend überarbeitet und mit ein paar neuen Features ausgestattet:

- Redcarpet wurde durch kramdown ersetzt und unterstützt damit auch die Markdown-Erweiterungen, die kramdown anbietet.
- Automatisches Verlinken von URLs
- HTML-Sanitation
- Das Syntax-Highlighting übernimmt nun das Gem 'pygments.rb'. Der Umweg über Pygmentizr fällt damit intern weg und verbessert die Reaktionszeiten deutlich.
- Das Frontend basiert nun auf AngularJS.
- Komplett überarbeiteter Quelltext.
- JSON-basierte API

kramdown, das automatische Verlinken und die HTML-Sanitation werden über das Gem '[slodown](https://github.com/hmans/slodown)' von Hendrik Mans erledigt.

Die neue JSON-basierte API ist über eine andere URL erreichbar:

`http://amplify.webcodr.de/api/2.0/transform`

Ein Beispiel-Request via POST:

~~~ json
{
 	"source": "# Hello World!"
}
~~~

Und die entsprechende Antwort von Amplify:

~~~ json
{
	"html": "<h1 id=\"hello-world\">Hello World!</h1>",
 	"source": "# Hello World!"
}
~~~

Wer, wie früher, ohne JSON auskommen möchte, nutzt bitte folgende URL:

`http://amplify.webcodr.de/api/1.0/transform`

Die bisherige Möglichkeit einfach einen POST-Request auf die Amplify-URL abzusetzen ist nur noch aus Gründen der Kompatibilität zu bestehenden Anwendungen aktiv, wird aber langfristig deaktiviert.

Zukünftige Features werde ich außerdem nur für die JSON-basierte API 2.0 implementieren.

Des weiteren plane ich Amplify langfristig nicht mehr auf Heroku laufen zu lassen, da die App einfach zu häufig in den Schlafmodus versetzt wird und anschließend sehr lange braucht, bis sie auf Anfragen reagiert.

Ich könnte zwar einfach einen Dyno hinzubuchen, aber das ist nicht gerade billig und es gibt wirklich kostengünstigere Möglichkeiten, Ruby-Web-Applikationen zu hosten -- beispielsweise bei [Uberspace.de](https://uberspace.de/).

Aus technischer Sicht dürfte noch interessant sein, dass Amplify nun mit Capybara automatisiert getestet wird und auf [Travis CI](https://travis-ci.org/WebCodr/Amplify) sowie testweise [Circle CI](https://circleci.com/) (mit automatischem Heroku-Deployment) läuft.
