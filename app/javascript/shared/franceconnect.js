var franceConnectKit = {};

(function (window) {
    var fconnect = {
        tracesUrl: '/traces',
        aboutUrl: ''
    };

    franceConnectKit.init = function () {
        //initCurrentHostnameSource();
        //includeFCCss();

        fconnect.currentHost = 'fcp.integ01.dev-franceconnect.fr';

        if (window.location.hostname == 'www.demarches-simplifiees.fr')
            fconnect.currentHost = 'app.franceconnect.gouv.fr';

        var fconnectProfile = document.getElementById('fconnect-profile');
        if (fconnectProfile) {
            var linkAccess = document.querySelector('#fconnect-profile > a');
            var fcLogoutUrl = fconnectProfile.getAttribute('data-fc-logout-url');
            var access = createFCAccessElement(fcLogoutUrl);
            fconnectProfile.appendChild(access);
            linkAccess.onclick = toggleElement.bind(access);
        }
    };

    var document = window.document;

    document.addEventListener('DOMContentLoaded', function () {
        franceConnectKit.init();
    });

    function initCurrentHostnameSource() {
        var currentScript = document.querySelector('script[src^="/assets/franceconnect"]').getAttribute('src');
        var parseUrl = currentScript.split('/');
        fconnect.currentHost = parseUrl[2];
    }

    function includeFCCss() {
        var ss = document.styleSheets;
        for (var i = 0, max = ss.length; i < max; i++) {
            if (ss[i].href == 'http://' + fconnect.currentHost + '/stylesheets/franceconnect.css' || ss[i].href == 'https://' + fconnect.currentHost + '/stylesheets/franceconnect.css')
                return;
        }

        var linkCss = document.createElement('link');
        linkCss.rel = 'stylesheet';
        linkCss.href = '//' + fconnect.currentHost + '/stylesheets/franceconnect.css';
        linkCss.type = 'text/css';
        linkCss.media = 'screen';

        document.getElementsByTagName('head')[0].appendChild(linkCss);
    }

    function toggleElement(event) {
        event.preventDefault();
        if (this.style.display === "block") {
            this.style.display = "none";
        } else {
            this.style.display = "block";
        }
    }

    function closeFCPopin(event) {
        event.preventDefault();
        fconnect.popin.className = 'fade-out';
        setTimeout(function () {
            document.body.removeChild(fconnect.popin);
        }, 200);
    }

    function openFCPopin() {
        fconnect.popin = document.createElement('div');
        fconnect.popin.id = 'fc-background';

        var iframe = createFCIframe();

        document.body.appendChild(fconnect.popin);

        fconnect.popin.appendChild(iframe);

        setTimeout(function () {
            fconnect.popin.className = 'fade-in';
        }, 200);
    }

    function createFCIframe() {
        var iframe = document.createElement("iframe");
        iframe.setAttribute('id', 'fconnect-iframe');
        iframe.frameBorder = 0;
        iframe.name = 'fconnect-iframe';
        return iframe;
    }

    function createFCAccessElement(logoutUrl) {
        var access = document.createElement('div');
        access.id = 'fconnect-access';
        access.innerHTML = '<h5>Vous êtes identifié grâce à FranceConnect</h5>';
        access.appendChild(createAboutLink());
        access.appendChild(document.createElement('hr'));
        access.appendChild(createHistoryLink());
        access.appendChild(createLogoutElement(logoutUrl));
        return access;
    }

    function createHistoryLink() {

        var historyLink = document.createElement('a');
        historyLink.target = 'fconnect-iframe';
        historyLink.href = '//' + fconnect.currentHost + fconnect.tracesUrl;
        historyLink.onclick = openFCPopin;
        historyLink.innerHTML = 'Historique des connexions/échanges de données';

        return historyLink;
    }

    function createAboutLink() {
        var aboutLink = document.createElement('a');
        aboutLink.href = fconnect.aboutUrl ? '//' + fconnect.currentHost + fconnect.aboutUrl : '#';
        if (fconnect.aboutUrl) {
            aboutLink.target = 'fconnect-iframe';
            aboutLink.onclick = openFCPopin;
        }
        aboutLink.innerHTML = 'Qu\'est-ce-que FranceConnect ?';

        return aboutLink;
    }

    function createLogoutElement(logoutUrl) {
        var elm = document.createElement('div');
        elm.className = 'logout';
        elm.innerHTML = '<a class="btn btn-default" href="' + logoutUrl + '">Se déconnecter</a>';
        return elm;
    }

    var eventMethod = window.addEventListener ? "addEventListener" : "attachEvent";
    var eventer = window[eventMethod];
    var messageEvent = eventMethod == "attachEvent" ? "onmessage" : "message";

    // Listen to message from child window
    eventer(messageEvent, function (e) {
        var key = e.message ? "message" : "data";
        var data = e[key];
        if (data === 'close_popup') {
            closeFCPopin(e);
        }
    }, false);
})(this);
