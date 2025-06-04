---
date: 2012-06-17T22:20:12+01:00
title: "PHP-Autoloader nach dem PSR-0-Standard"
---
Wenn's um das Schreiben eines Autoloaders in PHP geht, kochen viele Entwickler gern ihr eigenes Süppchen. Sofern nun mehrere gleichzeitig aktiv sind, kann das zu Problemen führen und ggf. sogar dafür sorgen, dass eine Alternative gesucht werden muss.

Die [PHP Framework Interoperability Group](https://github.com/php-fig/fig-standards) (kurz FIG) hat sich dieses Problems angenommen und eine Spezifikation für Autoloader entwickelt, die Interoperabilität sicherstellt.

Der [PSR-0-Standard](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-0.md) besteht aus ein paar recht simplen Regeln, die sich sehr einfach umsetzen lassen und z.T. sicher schon von vielen genutzt wurden:

- Ein qualifizierter Namespace hat folgende Struktur `\<Vendor Name>\(<Namespace>\)*<Class Name>`
- Jeder Namespace hat einen Haupt-Namespace (Vendor Name)
- Jeder Namespace kann beliebig viele Unter-Namespaces besitzen
- Jeder Namespace-Separator wird in einen `DIRECTOR_SEPARATOR` konvertiert, wenn aus dem Dateisystem geladen wird
- Das Zeichen "_" (Underscore) wird in einen `DIRECTORY_SEPARATOR` konvertiert und hat keine spezielle Bedeutung.
- Der qualifizierte Namespace inkl. Klasse bekommt die Endung ".php" angehängt, um die Datei zu laden.
- Namespaces, Vendor Names und Klassennamen dürfen alphabetische Zeichen in jeder Kombination aus Groß- und Kleinschreibung enthalten.

## Beispiel-Implementation ##

~~~ php
<?php

namespace WebCodr;

class Loader {

    public static function registerAutoloader() {
        return spl_autoload_register(array ('WebCodr\\Loader', 'load'));
    }

    public static function load($class) {
        if(substr($class, 0, 7) !== 'WebCodr') {
            return;
        }

        $libraryRoot = realpath(__DIR__ . '/../');
        $classFileName = str_replace(array('\\', '_'), DIRECTORY_SEPARATOR, $class) . '.php';
        $fileName = realpath($libraryRoot . DIRECTORY_SEPARATOR . $classFileName);

        if(is_readable($fileName)) {
            include_once($fileName);
        }
    }
}
~~~

Die Klasse stellt zwei statische Methoden bereit. Mit `Loader::registerAutoloader()` wird die Methode `Loader::load()` als SPL-Autoloader registriert.

`Loader::load()` prüft zuerst, ob sich die angeforderte Klasse überhaupt in Namespace WebCodr befindet. Falls dies nicht der Fall ist, wird durch den leeren Rückgabewert signalisiert, dass die Klasse mit diesem Autoloader nicht geladen werden kann und die SPL geht zum nächsten registrierten Autoloader über.

Anschließend wird der Pfad zur Klasse zusammengesetzt und die Datei mittels `include_once()` eingebunden. Optinal könnte man im Fehlerfall natürlich noch eine Exception werfen.

## Aufruf des Autoloaders ##

~~~ php
<?php

include_once('Loader.php');
\WebCodr\Loader::registerAutoloader();
~~~

## Fazit ##

PSR-0 ist schnell und einfach implementiert. Für neue Projekte gibt es also keinen Grund, sich nicht daran zu halten. In bestehendem Code könnte es recht aufwendig sein, den Standard umzusetzen -- je nach dem, welche Benamungsschemata und Verzeichnisstrukturen bereits verwendet werden.

Man sollte den Aufwand aber nicht scheuen. Was bringt einem schon die tollste Library oder ein cooles Framework, wenn es aufgrund eines schlecht implementierten Autoloaders, kaum eingesetzt werden kann?
