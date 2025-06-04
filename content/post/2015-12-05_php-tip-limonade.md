---
date: 2012-04-11T22:17:38+01:00
title: "PHP-Tip: Limonade"
---
Wer sich schon mal mit [Symfony](http://symfony.com/) oder ähnlichen PHP-Frameworks beschäftigt hat, kam sicher schnell zur Erkentnis, dass das die Dinger zwar viel können und generell eine tolle Sache sind, aber hohe Einstiegshürden haben bzw. viel Einarbeitungszeit benötigen, sowie für viele Projekte einfach überdimensioniert sind.

In Ruby hätte man für solche Fälle z.B. [Sinatra](http://www.sinatrarb.com/): übersichtlich, klein, schnell und flexibel. Mit [Limonade](http://limonade-php.github.com/) gibt es so ein Micro-Framework nun endlich für PHP, mit dem sich auch ähnlich elegant entwickeln lässt.

Es reicht eine Datei in ein Script einzubinden, die .htaccess-Datei anzupassen und schon kann man loslegen:

~~~ php
<?php

require_once 'vendors/limonade.php';

// lambda function (>= PHP 5.3)
dispatch('/hello/:name', function() {
    $name = params('name');

    return "Hello, {$name}";
});

run();
~~~

Das war es schon. Den ganzen Rest erledigt Limonade und das war noch lange nicht alles, was es kann. Die Routen-Definitionen können beispielsweise auch Wildcards oder reguläre Ausdrücke enthalten. Als Callback lassen sich selbstverständlich auch Objekte bzw. deren Methoden aufrufen (auch statisch) oder man gibt in klassischer Manier einen Funktionsnamen als String an.

Dazu gibt es eine Template Engine mit partiellen Templates, Capture-Möglichkeiten, JSON-Unterstützung, Hooks und Filtern.

Alles davon lässt sich ohne große Einarbeitung sofort nutzen. Natürlich muss man die integrierte Template Engine nicht nutzen und kann auch stattdessen einfach Twig oder Smarty verwenden.
