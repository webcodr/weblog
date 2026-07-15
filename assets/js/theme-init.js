(() => {
	try {
		const theme = localStorage.getItem("webcodr-theme");

		if (theme === "light" || theme === "dark") {
			document.documentElement.dataset.theme = theme;
		}
	} catch (_) {
		// The CSS media query still follows the OS preference if storage is blocked.
	}
})();
