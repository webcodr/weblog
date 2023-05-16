---
date: 2012-08-24T22:25:16+01:00
title: "Menlo Park, start your photocopiers ..."
slug: "menlo-park-start-your-photocopiers"
---
## ... oder warum Software-Patente und Patentkriege scheiße sind.

Gestern habe für die Share-Funktionen von Twitter, Google+ und Facebook jeweils ein Modul nach dem [CommonJS-Standard](http://www.commonjs.org/) gebaut, um sie in meinem [privaten Weblog](http://www.madcatswelt.org/) zu nutzen.

Daran ist nun nichts besonders, wenn ich nicht eine kleine Entdeckung gemacht hätte. Offenbar hat Facebook den nötigen JavaScript-Code von Twitter kopiert oder Twitter von Facebook.

## Quelltext vom Twitter

~~~ javascript
!function(d, s, id) {
	var js, fjs = d.getElementsByTagName(s)[0];

	if(!d.getElementById(id)) {
		js = d.createElement(s);
		js.id = id;
		js.src = "//platform.twitter.com/widgets.js";
		fjs.parentNode.insertBefore(js, fjs);
	}
}(document, "script", "twitter-wjs");
~~~

## Quelltext von Facebook:

~~~ javascript
(function(d, s, id) {
	var js, fjs = d.getElementsByTagName(s)[0];
	if(d.getElementById(id)) return;
	js = d.createElement(s);
	js.id = id;
	js.src = "//connect.facebook.net/de_DE/all.js#xfbml=1";
	fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
~~~

Zwecks der Lesbarkeit habe ich die Funktionen entsprechend formatiert.

Selbst Nicht-Programmierern dürften die Ähnlichkeiten kaum entgehen. Die Variablennamen sind identisch und sogar die Art der URL-Angabe ohne Protokoll. Selbst das if-Conditional und damit die Methode das externe JavaScript nicht zweimal einzubinden, stimmen überein -- nur die Schreibweise ist etwas anders.

Aus meiner Sicht geht dieses Vorgehen das vollkommen in Ordnung. Man muss nicht ständig das Rad neu erfinden. Gerade Programmierer tun das sehr gerne, obwohl es nur selten notwendig ist.

Twitter und Facebook sind Technologie-Vorreiter, neben Google die zwei wichtigsten im gesamten Netz -- warum sollten sie also nicht gegenseitig voneinander profitieren? Auch wenn es nur um einen Code-Schnippsel geht, der externe JavaScripts lädt.

Andere Firmen (Hallo, Oracle!) holen selbst bei wesentlich geringeren Quelltext-Ähnlichkeiten gleich die Klage-Keule raus. Durch die Möglichkeit in den USA Patente auf Software zu bekommen, ist sowas sogar oft von Erfolg gekrönt ...

Ich bin kein Verfechter von Open Source, auch wenn ich es grundsätzlich für eine gute Sache halte. Noch bin ich der Meinung, dass Software ein Allgemeingut wäre und jedem kostenlos zur Verfügung stehen müsse.

Jedem Entwickler muss das Recht zustehen, sein Produkt zu verkaufen und es schützen zu dürfen. Im Fall von Trivial-Patenten, geht es nicht mehr darum.

Man will nur noch der Konkurrenz schaden und Geld rausholen, obwohl man selbst oft mehr als genug hat. Firmen werden gekauft, um an die Patente zu kommen und anschließend andere Firmen mit Klagen zu überziehen.

Egal, ob Apple, Samsung, Motorola (Google), Nokia oder sonst wer. Hört endlich auf damit! Keiner eurer Kunden will Import-Verbote, absurd hohe Patentabgaben für verkaufte Geräte oder sonstige Auswüchse euer Advokaten-Armeen.

Aus Apples Sicht ist Android ein geklautes Produkt. Objektiv gesehen kann man dem sogar in Teilen zustimmen. Nur: na und?

Apple hat gute Ideen, Google hat gute Ideen. Nutzt sie, um euch gegenseitig zu verbessern und stellt diese lächerlichen Grabenkämpfe ein, die euch letztlich mehr schaden als nützen.
