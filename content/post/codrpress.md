---
date: 2012-10-21T22:26:30+01:00
title: "CodrPress"
---
Ich bin mal wieder so wahnsinnig und arbeite an einem Blog-System. Diesmal will ich das Rad aber nicht neu erfinden und ein zweites Wordpress bauen. Stattdessen orientiert sich CodrPress an [Schnitzelpress](https://github.com/hmans/schnitzelpress).

Da Schnitzelpress auf Ruby basiert und primär für den Einsatz auf Heroku ausgelegt ist, habe ich mich dazu entschieden mit [CodrPress](https://github.com/MadCatme/CodrPress) quasi eine PHP-Version von Schnitzelpress zu entwickeln.

Natürlich ist das wieder mal einfacher gesagt als getan, vor allem da es für diverse Ruby Gems, die Schnitzelpress nutzt, in der PHP-Welt kaum brauchbaren Ersatz gibt.

Mit [Redcarpet](https://github.com/vmg/redcarpet) und [CodeRay](https://github.com/rubychan/coderay) hat Ruby zwei wundervolle Gems, die sich um Markdown-Rendering bzw. Syntax-Highlighting kümmern.

CodrPress basiert auf meinem Projekt [MongoAppKit](https://github.com/MadCatme/mongoappkit), das widerrum auf [Silex](http://silex.sensiolabs.org/) sowie [Twig](http://twig.sensiolabs.org/) setzt und seine Abhängigkeiten mit [Composer](http://getcomposer.org/) regelt. Keine der PHP-basierten Lösungen, um diese zwei Ruby Gems zu ersetzen, bietet Composer-Unterstützung an und die Strukturen sind z.T. auch nicht [PSR-0-kompatibel](http://webcodr.de/2012/06/17/php-autoloader-nach-dem-psr-0-standard/), so dass ein Autoloading der Klassen nicht möglich ist.

Daher habe ich zwei neue Projekte aus der Taufe gehoben, die genau diesen Mangel beseitigen:

### SilexMarkdown

Da ich keine Lust und Zeit habe, selbst einen Markdown-Renderer zu schreiben, basiert [SilexMarkdown](https://github.com/MadCatme/SilexMarkdown) auf [php-markdown](https://github.com/michelf/php-markdown/) von Michel Fortin.

Ich musste es erstmal in brauchbare Struktur bringen, da das Original leider weder Namespaces nutzt und sogar zwei Klassen in einer Datei besitzt.

SilexMarkdown stellt nun eine Service-Prodiver-Klasse für Silex und eine entsprechende Twig-Extension zur Verfügung. Dazu wurde es noch mit einer Unterstützung für Code-Blöcke angereichert, um Syntax Highlighting wie in GitHub nutzen zu können.

### Radiant

Die Kern-Komponente von [Radiant](https://github.com/MadCatme/Radiant) ist ebenfalls nicht auf meinem Mist gewachsen und stammt aus dem Projekt [Nijikodo](https://github.com/ccampbell/nijikodo) von Clint Campbell.

Immerhin war die Grundlage schon mal PSR-0-kompatibel und damit auch relativ leicht Composer-tauglich zu machen.

Meine Arbeit bestand zum Großteil darin, entsprechende Unit-Tests zu schreiben und einige Fehler zu beseitigen und es in SilexMarkdown einzubinden.

## Qualität

Alle genannten Projekte, also MongoAppKit, SilexMarkdown, Radiant und CodrPress werden mittels [PHPUnit](https://github.com/sebastianbergmann/phpunit/) laufend von mir und automatisiert via [Travis CI](https://travis-ci.org/) getestet. Abgesehen von SilexMarkdown beträgt die Code-Coverage zwischen 70 - 90%.

## Style

Aktuell ist CodrPress mit dem vollständigen [Twitter Bootstrap](http://twitter.github.com/bootstrap/) versehen, um auch in der Entwicklunsphase ein halbwegs ahnsehnliches Design zu haben. Später werde ich nur ein paar Komponenten aus Bootstrap nutzen, z.B. das Grid und die responiven Fähigkeiten.

Für das Syntax-Highlighting habe ich ein Farb-Theme basierend auf meinem Farbschema von PhpStorm geschrieben, das auch Radiant beiliegt. Dank einer recht einfachen Struktur kann man sich auch sehr schnell ein eigenes Theme zusammenstellen.

## Ausblick

Die Frontend-Funktionen von CodrPress sind mit einer gefüllten Datenbank (Schnitzelpress-kompatibel) schon nutzbar. Homepage, Einzeldarstellung von Einträgen, eigene Seiten und das Markdown-Rendering mit Syntax-Highlighting funktionieren soweit einwandfrei.

Als nächstes werde ich einem Admin-Bereich und anschließend einem ansprechenden Design widmen.
