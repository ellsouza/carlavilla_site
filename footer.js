(function () {
    function safeGetHref(anchor) {
        if (!anchor) {
            return "";
        }
        return anchor.getAttribute("href") || "";
    }

    function sanitizeLinkForAnalytics(href) {
        if (!href) {
            return "";
        }

        if (href.startsWith("mailto:") || href.startsWith("tel:")) {
            return href.split("?")[0];
        }

        try {
            var url = new URL(href, window.location.href);
            if (url.hostname === "wa.me" || url.hostname.endsWith("whatsapp.com")) {
                url.search = "";
                url.hash = "";
            }
            return url.toString();
        } catch (err) {
            return href;
        }
    }

    function trackContactClick(method, anchor) {
        if (typeof window.gtag !== "function") {
            return;
        }

        var href = safeGetHref(anchor);
        var payload = {
            contact_method: method,
            link_url: sanitizeLinkForAnalytics(href),
            link_text: (anchor && (anchor.textContent || "").trim()) || ""
        };

        window.gtag("event", "contact_click", payload);
        window.gtag("event", "contact_" + method + "_click", payload);
    }

    function setupContactTracking() {
        document.addEventListener(
            "click",
            function (event) {
                var target = event.target;
                if (!target || typeof target.closest !== "function") {
                    return;
                }

                var anchor = target.closest("a");
                if (!anchor) {
                    return;
                }

                var href = safeGetHref(anchor).trim();
                if (!href) {
                    return;
                }

                if (href.startsWith("mailto:")) {
                    trackContactClick("email", anchor);
                    return;
                }

                if (href.startsWith("tel:")) {
                    trackContactClick("phone", anchor);
                    return;
                }

                if (href.indexOf("wa.me/") !== -1 || href.indexOf("whatsapp.com/") !== -1) {
                    trackContactClick("whatsapp", anchor);
                }
            },
            true
        );
    }
    function normalizeBase(base) {
        if (base === "/") {
            return "/";
        }
        if (!base || base === ".") {
            return "";
        }
        return base.replace(/\/+$/, "");
    }

    function buildFooter(base) {
        var root = normalizeBase(base);
        var withBase = function (path) {
            if (root === "/") {
                return "/" + path.replace(/^\/+/, "");
            }
            return root ? root + "/" + path : path;
        };

        return [
            '<footer id="footer" class="footer">',
            '<div class="footer-container">',
            '<div class="footer-brand">',
            '<img src="' + withBase("imagens/logo.png") + '" class="footer-logo" alt="Logo Carla Villa">',
            '<h3>Carla Villa</h3>',
            '<p class="footer-crp">CRP 04/14.761</p>',
            '<p class="footer-area">TCC e Terapia do Esquema</p>',
            "</div>",
            '<div class="footer-nav">',
            "<h4>Navegação</h4>",
            '<a href="' + withBase('index.html#inicio') + '">Início</a>',
            '<a href="' + withBase('index.html#sobre') + '">Sobre</a>',
            '<a href="' + withBase('index.html#para-quem') + '">Para quem é</a>',
            '<a href="' + withBase('psicologa-online-brasileiros-no-exterior.html') + '">Brasileiros no exterior</a>',
            '<a href="' + withBase('index.html#como-funciona') + '">Como funciona</a>',
            '<a href="' + withBase('textos/') + '">Arquivo de textos</a>',
            "</div>",
            '<div class="footer-contact">',
            "<h4>Contato</h4>",
            "<p>Telefone<br>",
            '<a href="https://wa.me/5531993440038?text=Ol%C3%A1%21%20Estou%20vindo%20do%20site%20e%20quero%20agendar%20uma%20primeira%20conversa.">+55 (31) 99344-0038</a>',
            "</p>",
            "<p>E-mail<br>",
            '<a href="mailto:carlavilhenas@gmail.com">carlavilhenas@gmail.com</a>',
            "</p>",
            "<p>Atendimento online</p>",
            "</div>",
            '<div class="footer-about">',
            "<h4>Sobre o atendimento</h4>",
            "<p>",
            "Psicoterapia online com base em Terapia Cognitivo-Comportamental (TCC)",
            "e Terapia do Esquema, voltada a adultos que desejam compreender e",
            "transformar padrões emocionais persistentes.",
            "</p>",
            "</div>",
            "</div>",
            '<div class="footer-bottom">',
            "<p>&copy; 2026 Carla Villa Psicologia - Todos os direitos reservados</p>",
            '<p class="footer-etica">Este site possui caráter informativo e não substitui atendimento psicológico.</p>',
            '<p class="footer-etica">Atendimento realizado conforme o Código de Ética Profissional do Psicólogo (CFP).</p>',
            '<p class="footer-etica">Em caso de crise emocional ou emergência, procure suporte imediato ou serviços de emergência da sua região.</p>',
         '<p class="footer-dev">Desenvolvimento do site: <a href="https://ellsouza.github.io/ellen-portfolio/" target="_blank" rel="noopener"><strong>Ellen Souza</strong></a></p>',
            "</div>",
            "</footer>"
        ].join("\n");
    }

    function injectFooters() {
        var containers = document.querySelectorAll("[data-site-footer]");
        containers.forEach(function (container) {
            var base = container.getAttribute("data-base") || ".";
            container.outerHTML = buildFooter(base);
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", injectFooters);
    } else {
        injectFooters();
    }

    setupContactTracking();
})();



