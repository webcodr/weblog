---
date: 2013-02-02T22:29:07+01:00
title: Services ftw!
---
Wer kennt das nicht? Man findet eine nette Software-Bibliothek in einer bestimmten Sprache, die vom Server der eigenen Web-Applikation nicht unterstützt wird oder nur sehr umständlich auf andere Weise genutzt werden kann.

So erging es mir mit Tools für Markdown-Rendering und server-basiertem Syntax-Highlighting. Zwar habe ich dafür ja im Oktober die Composer-Pakete SilexMarkdown und Radiant geschrieben, die beide auf bereits vorhandenen Bibliotheken fußen.

Ich war mit beiden nie recht glücklich. Für Ruby und Python gibt es viel schönere, wesentlich umfangreichere Lösungen:

- Pygments ist ein Python geschriebener Syntax-Highlighter, der nahezu jede relevante Sprache unterstützt -- selbst esoterische Merkwürdigkeiten wie Brainfuck.

- Redcarpet wurde in Ruby verfasst und bietet einen sehr leicht erweiter- und modifizierbaren Markdown-Renderer.

Gerade für ein Blog-System wie CodrPress liegt es nahe, beide zu kombinieren und damit zumindest teilweise GitHub flavoured Markdown zu unterstützen.

Wie bekomme ich also drei Programmiersprachen unter einen Hut, ohne dass CodrPress nur auf angepassten Server-Konfigurationen läuft? Ganz einfach: Services!

## Pygmentizr

[Pygmentizr](http://pygmentizr.herokuapp.com/) ist logischerweise in Python geschrieben, um Pygments nutzen zu können.

Per POST-Anfrage auf die verlinkte URL erreicht man den eigentlichen Service, der als Parameter die Sprache und den Quelltext erwartet. Zurück kommt HTML, das nur noch per CSS hübsch gemacht werden muss.

Ein entsprechendes Stylesheet für den bekannten Monokai-Stil ist auf der Seite verlinkt oder im GitHub-Repository zu finden.

[Pygmentizr bei GitHub](https://github.com/MadCatme/Pygmentizr)

## Amplifyr

[Amplifyr](http://amplifyr.herokuapp.com/) nutzt Redcarpet und bindet Pygmentizr als Syntax-Highlighter ein.

Wie Pygmentizr lässt sich Amplifyr per POST-Anfrage ansprechen und gibt den in HTML konvertierten Markdown-Quelltext zurück.

[Amplifyr bei GitHub](https://github.com/MadCatme/Amplifyr)

Beide Dienste laufen auf der Cloud-Plattform Heroku.

## CodrPress-Integration

Um beide Services in CodrPress nutzen können, habe ich in SilexMarkdown ein paar Umbauten vorgenommen. Beim Registrieren des Service-Providers in einer Silex-Applikation, lässt sich nun ganz einfach übergeben, ob der eingebaute Renderer samt Radiant oder Amplifyr genutzt werden soll. Eine entsprechende Anleitung findet sich in der ReadMe-Datei des SilexMarkdown-Repositories bei GitHub.

Beide Dienste sind bei Heroku untergebracht und kosten mich keinen Cent. daher gebe ich die Nutzung für jeden frei. Viel Spaß!
