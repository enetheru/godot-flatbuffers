'use strict';

var obsidian = require('obsidian');

class GdscriptSyntaxPlugin extends obsidian.Plugin {
    onload() {
        var self = this;

        // The defineSimpleMode function is not immediately available during
        // onload, so continue to try and define the language until it is.
        const setupInterval = setInterval(() => {
            if (CodeMirror && CodeMirror.defineSimpleMode) {
                const mode = {
                    start: [
                        { regex: /\b0x[0-9a-f]+\b/i, token: "number" },
                        { regex: /\b-?\d+\b/, token: "number" },
                        { regex: /#.+/, token: 'comment' },
                        { regex: /\s*(@onready|@export)\b/, token: 'keyword' },
                        { regex: /\b(?:and|as|assert|await|break|breakpoint|const|continue|elif|else|enum|for|if|in|is|master|mastersync|match|not|null|or|pass|preload|puppet|puppetsync|remote|remotesync|return|self|setget|static|tool|var|while|yield)\b/, token: 'keyword' },
                        { regex: /[()\[\]{},]/, token: "meta" },

                        // The words following func, class_name and class should be highlighted as attributes,
                        // so push onto the definition stack
                        { regex: /\b(func|class_name|class|extends|signal)\b/, token: "keyword", push: "definition" },

                        { regex: /@?(?:("|')(?:(?!\1)[^\n\\]|\\[\s\S])*\1(?!"|')|"""(?:[^\\]|\\[\s\S])*?""")/, token: "string" },
                        { regex: /\$[\w\/]+\b/, token: 'variable' },
                        { regex: /\:[\s]*$/, token: 'operator' },
                        { regex: /\:[ ]*/, token: 'meta', push: 'var_type' },
                        { regex: /\->[ ]*/, token: 'operator', push: 'definition' },
                        { regex: /\+|\*|-|\/|:=|>|<|\^|&|\||%|~|=/, token: "operator" },
                        { regex: /\b(?:false|true)\b/, token: 'number' },
                        { regex: /\b[A-Z][A-Z_\d]*\b/, token: 'operator' },
                    ],
                    var_type: [
                        { regex: /(\w+)/, token: 'attribute', pop: true },
                    ],
                    definition: [
                        { regex: /(\w+)/, token: "attribute", pop: true }
                    ]
                };

                CodeMirror.defineSimpleMode('gdscript', mode);
                CodeMirror.defineSimpleMode('GDScript', mode);
                CodeMirror.defineSimpleMode('GDscript', mode);

                self.app.workspace.iterateAllLeaves((leaf) => {
                    leaf.rebuildView();
                 });

                 clearInterval(setupInterval);
            }
        }, 100);
    }

    onunload() {
        delete CodeMirror.modes['gdscript'];
        delete CodeMirror.modes['GDScript'];
        delete CodeMirror.modes['GDscript'];
    }
}

module.exports = GdscriptSyntaxPlugin;
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFpbi5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL21haW4uanMiXSwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHsgUGx1Z2luIH0gZnJvbSAnb2JzaWRpYW4nO1xuXG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIEdkc2NyaXB0U3ludGF4UGx1Z2luIGV4dGVuZHMgUGx1Z2luIHtcbiAgICBvbmxvYWQoKSB7XG4gICAgICAgIHZhciBzZWxmID0gdGhpcztcblxuICAgICAgICAvLyBUaGUgZGVmaW5lU2ltcGxlTW9kZSBmdW5jdGlvbiBpcyBub3QgaW1tZWRpYXRlbHkgYXZhaWxhYmxlIGR1cmluZ1xuICAgICAgICAvLyBvbmxvYWQsIHNvIGNvbnRpbnVlIHRvIHRyeSBhbmQgZGVmaW5lIHRoZSBsYW5ndWFnZSB1bnRpbCBpdCBpcy5cbiAgICAgICAgY29uc3Qgc2V0dXBJbnRlcnZhbCA9IHNldEludGVydmFsKCgpID0+IHtcbiAgICAgICAgICAgIGlmIChDb2RlTWlycm9yICYmIENvZGVNaXJyb3IuZGVmaW5lU2ltcGxlTW9kZSkge1xuICAgICAgICAgICAgICAgIGNvbnN0IG1vZGUgPSB7XG4gICAgICAgICAgICAgICAgICAgIHN0YXJ0OiBbXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFxiMHhbMC05YS1mXStcXGIvaSwgdG9rZW46IFwibnVtYmVyXCIgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXGItP1xcZCtcXGIvLCB0b2tlbjogXCJudW1iZXJcIiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogLyMuKy8sIHRva2VuOiAnY29tbWVudCcgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXHMqKEBvbnJlYWR5fEBleHBvcnQpXFxiLywgdG9rZW46ICdrZXl3b3JkJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcYig/OmFuZHxhc3xhc3NlcnR8YXdhaXR8YnJlYWt8YnJlYWtwb2ludHxjb25zdHxjb250aW51ZXxlbGlmfGVsc2V8ZW51bXxmb3J8aWZ8aW58aXN8bWFzdGVyfG1hc3RlcnN5bmN8bWF0Y2h8bm90fG51bGx8b3J8cGFzc3xwcmVsb2FkfHB1cHBldHxwdXBwZXRzeW5jfHJlbW90ZXxyZW1vdGVzeW5jfHJldHVybnxzZWxmfHNldGdldHxzdGF0aWN8dG9vbHx2YXJ8d2hpbGV8eWllbGQpXFxiLywgdG9rZW46ICdrZXl3b3JkJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1soKVxcW1xcXXt9LF0vLCB0b2tlbjogXCJtZXRhXCIgfSxcblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gVGhlIHdvcmRzIGZvbGxvd2luZyBmdW5jLCBjbGFzc19uYW1lIGFuZCBjbGFzcyBzaG91bGQgYmUgaGlnaGxpZ2h0ZWQgYXMgYXR0cmlidXRlcyxcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIHNvIHB1c2ggb250byB0aGUgZGVmaW5pdGlvbiBzdGFja1xuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcYihmdW5jfGNsYXNzX25hbWV8Y2xhc3N8ZXh0ZW5kc3xzaWduYWwpXFxiLywgdG9rZW46IFwia2V5d29yZFwiLCBwdXNoOiBcImRlZmluaXRpb25cIiB9LFxuXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvQD8oPzooXCJ8JykoPzooPyFcXDEpW15cXG5cXFxcXXxcXFxcW1xcc1xcU10pKlxcMSg/IVwifCcpfFwiXCJcIig/OlteXFxcXF18XFxcXFtcXHNcXFNdKSo/XCJcIlwiKS8sIHRva2VuOiBcInN0cmluZ1wiIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFwkW1xcd1xcL10rXFxiLywgdG9rZW46ICd2YXJpYWJsZScgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXDpbXFxzXSokLywgdG9rZW46ICdvcGVyYXRvcicgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXDpbIF0qLywgdG9rZW46ICdtZXRhJywgcHVzaDogJ3Zhcl90eXBlJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcLT5bIF0qLywgdG9rZW46ICdvcGVyYXRvcicsIHB1c2g6ICdkZWZpbml0aW9uJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcK3xcXCp8LXxcXC98Oj18Pnw8fFxcXnwmfFxcfHwlfH58PS8sIHRva2VuOiBcIm9wZXJhdG9yXCIgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXGIoPzpmYWxzZXx0cnVlKVxcYi8sIHRva2VuOiAnbnVtYmVyJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcYltBLVpdW0EtWl9cXGRdKlxcYi8sIHRva2VuOiAnb3BlcmF0b3InIH0sXG4gICAgICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICAgICAgICAgICAgIHZhcl90eXBlOiBbXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvKFxcdyspLywgdG9rZW46ICdhdHRyaWJ1dGUnLCBwb3A6IHRydWUgfSxcbiAgICAgICAgICAgICAgICAgICAgXSxcbiAgICAgICAgICAgICAgICAgICAgZGVmaW5pdGlvbjogW1xuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogLyhcXHcrKS8sIHRva2VuOiBcImF0dHJpYnV0ZVwiLCBwb3A6IHRydWUgfVxuICAgICAgICAgICAgICAgICAgICBdXG4gICAgICAgICAgICAgICAgfTtcblxuICAgICAgICAgICAgICAgIENvZGVNaXJyb3IuZGVmaW5lU2ltcGxlTW9kZSgnZ2RzY3JpcHQnLCBtb2RlKTtcbiAgICAgICAgICAgICAgICBDb2RlTWlycm9yLmRlZmluZVNpbXBsZU1vZGUoJ0dEU2NyaXB0JywgbW9kZSk7XG4gICAgICAgICAgICAgICAgQ29kZU1pcnJvci5kZWZpbmVTaW1wbGVNb2RlKCdHRHNjcmlwdCcsIG1vZGUpO1xuXG4gICAgICAgICAgICAgICAgc2VsZi5hcHAud29ya3NwYWNlLml0ZXJhdGVBbGxMZWF2ZXMoKGxlYWYpID0+IHtcbiAgICAgICAgICAgICAgICAgICAgbGVhZi5yZWJ1aWxkVmlldygpO1xuICAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgICBjbGVhckludGVydmFsKHNldHVwSW50ZXJ2YWwpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9LCAxMDApO1xuICAgIH1cblxuICAgIG9udW5sb2FkKCkge1xuICAgICAgICBkZWxldGUgQ29kZU1pcnJvci5tb2Rlc1snZ2RzY3JpcHQnXTtcbiAgICAgICAgZGVsZXRlIENvZGVNaXJyb3IubW9kZXNbJ0dEU2NyaXB0J107XG4gICAgICAgIGRlbGV0ZSBDb2RlTWlycm9yLm1vZGVzWydHRHNjcmlwdCddO1xuICAgIH1cbn1cbiJdLCJuYW1lcyI6WyJQbHVnaW4iXSwibWFwcGluZ3MiOiI7Ozs7QUFHZSxNQUFNLG9CQUFvQixTQUFTQSxlQUFNLENBQUM7QUFDekQsSUFBSSxNQUFNLEdBQUc7QUFDYixRQUFRLElBQUksSUFBSSxHQUFHLElBQUksQ0FBQztBQUN4QjtBQUNBO0FBQ0E7QUFDQSxRQUFRLE1BQU0sYUFBYSxHQUFHLFdBQVcsQ0FBQyxNQUFNO0FBQ2hELFlBQVksSUFBSSxVQUFVLElBQUksVUFBVSxDQUFDLGdCQUFnQixFQUFFO0FBQzNELGdCQUFnQixNQUFNLElBQUksR0FBRztBQUM3QixvQkFBb0IsS0FBSyxFQUFFO0FBQzNCLHdCQUF3QixFQUFFLEtBQUssRUFBRSxrQkFBa0IsRUFBRSxLQUFLLEVBQUUsUUFBUSxFQUFFO0FBQ3RFLHdCQUF3QixFQUFFLEtBQUssRUFBRSxXQUFXLEVBQUUsS0FBSyxFQUFFLFFBQVEsRUFBRTtBQUMvRCx3QkFBd0IsRUFBRSxLQUFLLEVBQUUsS0FBSyxFQUFFLEtBQUssRUFBRSxTQUFTLEVBQUU7QUFDMUQsd0JBQXdCLEVBQUUsS0FBSyxFQUFFLHlC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
