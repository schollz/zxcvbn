    var socket;
    var imageTimer;

    // <keyboard>
    // testbed: https://jsfiddle.net/r9ec6mwj/11/
    document.addEventListener("keydown", keydown);
    document.addEventListener("keyup", keyup);
    var keys = new Object();
    keyboard_codes = new Object();
    keyboard_codes[0] = 'RESERVED'
    keyboard_codes[1] = 'ESCAPE'
    keyboard_codes[2] = '1'
    keyboard_codes[3] = '2'
    keyboard_codes[4] = '3'
    keyboard_codes[5] = '4'
    keyboard_codes[6] = '5'
    keyboard_codes[7] = '6'
    keyboard_codes[8] = '7'
    keyboard_codes[9] = '8'
    keyboard_codes[10] = '9'
    keyboard_codes[11] = '0'
    keyboard_codes[12] = 'MINUS'
    keyboard_codes[13] = 'EQUAL'
    keyboard_codes[14] = 'BACKSPACE'
    keyboard_codes[15] = 'TAB'
    keyboard_codes[16] = 'Q'
    keyboard_codes[17] = 'W'
    keyboard_codes[18] = 'E'
    keyboard_codes[19] = 'R'
    keyboard_codes[20] = 'T'
    keyboard_codes[21] = 'Y'
    keyboard_codes[22] = 'U'
    keyboard_codes[23] = 'I'
    keyboard_codes[24] = 'O'
    keyboard_codes[25] = 'P'
    keyboard_codes[26] = 'BRACKETLEFT'
    keyboard_codes[27] = 'BRACKETRIGHT'
    keyboard_codes[28] = 'ENTER'
    keyboard_codes[29] = 'CONTROLLEFT'
    keyboard_codes[30] = 'A'
    keyboard_codes[31] = 'S'
    keyboard_codes[32] = 'D'
    keyboard_codes[33] = 'F'
    keyboard_codes[34] = 'G'
    keyboard_codes[35] = 'H'
    keyboard_codes[36] = 'J'
    keyboard_codes[37] = 'K'
    keyboard_codes[38] = 'L'
    keyboard_codes[39] = 'SEMICOLON'
    keyboard_codes[40] = 'QUOTE'
    keyboard_codes[41] = 'GRAVE'
    keyboard_codes[42] = 'SHIFTLEFT'
    keyboard_codes[43] = 'BACKSLASH'
    keyboard_codes[44] = 'Z'
    keyboard_codes[45] = 'X'
    keyboard_codes[46] = 'C'
    keyboard_codes[47] = 'V'
    keyboard_codes[48] = 'B'
    keyboard_codes[49] = 'N'
    keyboard_codes[50] = 'M'
    keyboard_codes[51] = 'COMMA'
    keyboard_codes[52] = 'PERIOD'
    keyboard_codes[53] = 'SLASH'
    keyboard_codes[54] = 'SHIFTRIGHT'
    keyboard_codes[55] = 'KPASTERISK'
    keyboard_codes[56] = 'ALTLEFT'
    keyboard_codes[57] = 'SPACE'
    keyboard_codes[58] = 'CAPSLOCK'
    keyboard_codes[59] = 'F1'
    keyboard_codes[60] = 'F2'
    keyboard_codes[61] = 'F3'
    keyboard_codes[62] = 'F4'
    keyboard_codes[63] = 'F5'
    keyboard_codes[64] = 'F6'
    keyboard_codes[65] = 'F7'
    keyboard_codes[66] = 'F8'
    keyboard_codes[67] = 'F9'
    keyboard_codes[68] = 'F10'
    keyboard_codes[69] = 'NUMLOCK'
    keyboard_codes[70] = 'SCROLLLOCK'
    keyboard_codes[71] = 'KP7'
    keyboard_codes[72] = 'KP8'
    keyboard_codes[73] = 'KP9'
    keyboard_codes[74] = 'KPMINUS'
    keyboard_codes[75] = 'KP4'
    keyboard_codes[76] = 'KP5'
    keyboard_codes[77] = 'KP6'
    keyboard_codes[78] = 'KPPLUS'
    keyboard_codes[79] = 'KP1'
    keyboard_codes[80] = 'KP2'
    keyboard_codes[81] = 'KP3'
    keyboard_codes[82] = 'KP0'
    keyboard_codes[83] = 'KPDOT'
    keyboard_codes[85] = 'ZENKAKUHANKAKU'
    keyboard_codes[86] = '102ND'
    keyboard_codes[87] = 'F11'
    keyboard_codes[88] = 'F12'
    keyboard_codes[89] = 'RO'
    keyboard_codes[90] = 'KATAKANA'
    keyboard_codes[91] = 'HIRAGANA'
    keyboard_codes[92] = 'HENKAN'
    keyboard_codes[93] = 'KATAKANAHIRAGANA'
    keyboard_codes[94] = 'MUHENKAN'
    keyboard_codes[95] = 'KPJPCOMMA'
    keyboard_codes[96] = 'KPENTER'
    keyboard_codes[97] = 'CONTROLRIGHT'
    keyboard_codes[98] = 'KPSLASH'
    keyboard_codes[99] = 'SYSRQ'
    keyboard_codes[100] = 'ALTRIGHT'
    keyboard_codes[101] = 'LINEFEED'
    keyboard_codes[102] = 'HOME'
    keyboard_codes[103] = 'ARROWUP'
    keyboard_codes[104] = 'PAGEUP'
    keyboard_codes[105] = 'ARROWLEFT'
    keyboard_codes[106] = 'ARROWRIGHT'
    keyboard_codes[107] = 'ARROWEND'
    keyboard_codes[108] = 'ARROWDOWN'
    keyboard_codes[109] = 'PAGEDOWN'
    keyboard_codes[110] = 'INSERT'
    keyboard_codes[111] = 'DELETE'
    keyboard_codes[112] = 'MACRO'
    keyboard_codes[113] = 'MUTE'
    keyboard_codes[114] = 'VOLUMEDOWN'
    keyboard_codes[115] = 'VOLUMEUP'
    keyboard_codes[116] = 'POWER'
    keyboard_codes[117] = 'KPEQUAL'
    keyboard_codes[118] = 'KPPLUSMINUS'
    keyboard_codes[119] = 'PAUSE'
    keyboard_codes[120] = 'SCALE'
    keyboard_codes[121] = 'KPCOMMA'
    keyboard_codes[122] = 'HANGUEL'
    keyboard_codes[123] = 'HANJA'
    keyboard_codes[124] = 'YEN'
    keyboard_codes[125] = 'LEFTMETA'
    keyboard_codes[126] = 'RIGHTMETA'
    keyboard_codes[127] = 'COMPOSE'
    codes_keyboard = new Object();
    for (const [key, value] of Object.entries(keyboard_codes)) {
        codes_keyboard[value] = parseInt(key);
    }




    function isElementInViewport(el) {
        // Special bonus for those using jQuery
        if (typeof jQuery === "function" && el instanceof jQuery) {
            el = el[0];
        }

        var rect = el.getBoundingClientRect();

        return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && /* or $(window).height() */
            rect.right <= (window.innerWidth || document.documentElement.clientWidth) /* or $(window).width() */
        );
    }

    //or however you are calling your method
    function keyevent(event, down) {
        code = event.code.toUpperCase();
        if (code.startsWith("KEY")) {
            code = code.slice(3);
        }
        if (code.startsWith("DIGIT")) {
            code = code.slice(5);
        }
        if (code.startsWith("NUMPAD")) {
            code = code.slice(6);
        }
        if (down) {
            if (!(code in keys) || keys[code] == 0) {
                keys[code] = 1;
            } else {
                keys[code] = 2;
            }
        } else {
            keys[code] = 0;
        }
        console.log(keys[code], codes_keyboard[code]);
        socket.send(JSON.stringify({
            kind: "keyboard",
            n: keys[code],
            z: codes_keyboard[code],
        }));
    }

    function keydown(event) {
        if (isElementInViewport(document.getElementById('norns_screen'))) {
            event.preventDefault();
            keyevent(event, true);
        }
    }

    function keyup(event) {
        if (isElementInViewport(document.getElementById('norns_screen'))) {
            event.preventDefault();
            keyevent(event, false);
        }
    }
    // </keyboard>


    var sourceElement = document.querySelector("source");
    var originalSourceUrl = sourceElement.getAttribute("src");
    var audioElement = document.querySelector("audio");

    function toggle_play() {
        if (audioElement.paused) {
            play();
        } else {
            pause();
        }
    }

    $('#streamvolume').on('change', function() {
        console.log(`changing volume to ${this.value}`)
        $('audio').prop("volume", this.value);
    });

    function pause() {
        $('#streamplay').text('play')
        sourceElement.setAttribute("src", "");
        audioElement.pause();
        // settimeout, otherwise pause event is not raised normally
        setTimeout(function() {
            audioElement.load(); // This stops the stream from downloading
        });
    }

    function play() {
        $('#streamplay').text('...')
        console.log("reloading stream")
        sourceElement.setAttribute("src", originalSourceUrl + "?" + new Date().getTime());
        audioElement.load();
        setTimeout(function() {
            $('#streamplay').text('pause')
            console.log("playing stream")
            audioElement.play();
        }, 1500);
    }


    function getAvg(values) {
        if (values.length === 0) return 0;

        values.sort(function(a, b) {
            return a - b;
        });

        var half = Math.floor(values.length / 2);

        if (values.length % 2)
            return values[half];

        return (values[half - 1] + values[half]) / 2.0;

        //   if (grades.length==0) {
        //       return 0;
        //   }
        // const total = grades.reduce((acc, c) => acc + c, 0);
        // return total / grades.length;
    }

    function randomString(length) {
        var result = '';
        var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        var charactersLength = characters.length;
        for (var i = 0; i < length; i++) {
            result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        return result;
    }


    function debounce(func, wait, immediate) {
        var timeout;
        return function() {
            var context = this,
                args = arguments;
            var later = function() {
                timeout = null;
                if (!immediate) func.apply(context, args);
            };
            var callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) func.apply(context, args);
        };
    };

    var twitchActivated = false;
    var keys = [];
    var encs = [];

    function currentTime() {
        return (new Date()).getTime();
    }

    encs = [0, 1, 2].map(function(i) {
        let last_time = currentTime();
        let value = 0;
        let z = 0;
        let consecutive_turns = 0;
        return {
            change: function(v) {
                if (currentTime() - last_time < 50) {
                    // last_time = currentTime()
                    return
                }
                dif = (v - value);
                value = v;
                console.log(`v: ${v}, value: ${value}, dif: ${dif}`);
                if (Math.abs(dif) > 50 || Math.abs(dif) < 0.1) {
                    // last_time = currentTime()
                    return
                }
                last_time = currentTime()

                var multiplier = 1;
                if (Math.abs(dif) > 5) {
                    multiplier = Math.floor(Math.abs(dif));
                } else if (Math.abs(dif) > 3) {
                    multiplier = 2;
                }
                z = Math.sign(dif) * multiplier;
                console.log(z);
                if (socket != null) {
                    socket.send(JSON.stringify({
                        kind: "enc",
                        n: i + 1,
                        z: z,
                    }))
                }
            },
            val: function() {
                return z;
            }
        }
    });

    keys = [0, 1, 2].map(function(i) {
        let last_time = currentTime();
        let value = 0;
        let fast_clicked = false;
        return {
            reset: function() {
                value = 0;
                $("#k" + i).removeClass("latched")
                if (socket != null) {
                    socket.send(JSON.stringify({
                        kind: "key",
                        n: i + 1,
                        z: value,
                    }))
                }
            },
            change: function() {
                //console.log(i + " clicked")
                value = 1 - value;
                $("#k" + i).toggleClass("latched")
                if (currentTime() - last_time < 500 && value == 0) {
                    //console.log("fast click!")
                    fast_clicked = true
                } else {
                    //console.log("slow click")
                    fast_clicked = false
                }
                last_time = currentTime();
                if (i == 0 && socket != null) {
                    socket.send(JSON.stringify({
                        kind: "key",
                        n: i + 1,
                        z: value,
                        fast: fast_clicked,
                    }))
                } else if (socket != null) {
                    socket.send(JSON.stringify({
                        kind: "key",
                        n: i + 1,
                        z: value,
                    }))
                }
            },
            val: function() {
                return value;
            },
            get_fast_clicked: function() {
                return fast_clicked;
            }
        }
    });

    for (var i = 0; i < 3; i++) {
        var knobWidthHeight = Math.round((window.innerWidth) * 0.1);
        console.log(knobWidthHeight)
        $(`.enc${i}`).knob({
            'change': encs[i].change,
        });

        if (i == 0) {
            document.getElementById("k" + i).addEventListener("click", keys[i].change);
            //     document.getElementById("k" + i).addEventListener("mouseleave", keys[i].reset);
        } else {
            document.getElementById("k" + i).addEventListener("mousedown", keys[i].change);
            document.getElementById("k" + i).addEventListener("mouseup", keys[i].change);
        }
    }

    function updateVolume(v) {
        document.getElementById("volumePercent").innerText = v
        if (audioAllowed) {
            gainNode.gain.value = v / 100;
        }
    }

    function base64ToArrayBuffer(base64) {
        var binary_string = window.atob(base64);
        var len = binary_string.length;
        var bytes = new Uint8Array(len);
        for (var i = 0; i < len; i++) {
            bytes[i] = binary_string.charCodeAt(i);
        }
        return bytes.buffer;
    }


    const socketMessageListener = (e) => {
        data = JSON.parse(e.data);
        if ('img' in data) {
            document.getElementById('norns_screen').setAttribute(
                'src',
                'data:image/png;base64,' + data['img']
            );
        }
    };
    const socketOpenListener = (e) => {
        console.log('Connected');
        if (imageTimer) {
            clearInterval(imageTimer);
        }
        imageTimer = setInterval(function() {
            if (isElementInViewport(document.getElementById('norns_screen'))) {
                socket.send(JSON.stringify({
                    kind: "img",
                }));
            }
        }, 100);
    };
    const socketErrorListener = (e) => {
        console.error(e);
    }
    const socketCloseListener = (e) => {
        if (socket) {
            console.log('Disconnected.');
        }
        var url = "wss://play.norns.online/ws";
        socket = new WebSocket(url);
        socket.onopen = socketOpenListener;
        socket.onmessage = socketMessageListener;
        socket.onclose = socketCloseListener;
        socket.onerror = socketErrorListener;
    };
    window.addEventListener('load', (event) => {
        socketCloseListener();
        // setInterval(function() {
        //     document.getElementById('img').src = '/screen.png?rand=' + Math.random();
        // },1000);
    });