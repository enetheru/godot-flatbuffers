'use strict';

var obsidian = require('obsidian');

class GdscriptSyntaxPlugin extends obsidian.Plugin {
    onload() {
        var self = this;

        // The defineSimpleMode function is not immediately available during
        // onload, so continue to try and define the language until it is.
        const setupInterval = setInterval(() => {
            if (CodeMirror && CodeMirror.defineSimpleMode) {
                CodeMirror.defineSimpleMode("gdscript", {
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
                });

                self.app.workspace.iterateAllLeaves((leaf) => {
                    leaf.rebuildView();
                 });

                 clearInterval(setupInterval);
            }
        }, 100);
    }

    onunload() {
        delete CodeMirror.modes['gdscript'];
    }
}

module.exports = GdscriptSyntaxPlugin;
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFpbi5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL21haW4uanMiXSwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHsgUGx1Z2luIH0gZnJvbSAnb2JzaWRpYW4nO1xuXG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIEdkc2NyaXB0U3ludGF4UGx1Z2luIGV4dGVuZHMgUGx1Z2luIHtcbiAgICBvbmxvYWQoKSB7XG4gICAgICAgIHZhciBzZWxmID0gdGhpcztcblxuICAgICAgICAvLyBUaGUgZGVmaW5lU2ltcGxlTW9kZSBmdW5jdGlvbiBpcyBub3QgaW1tZWRpYXRlbHkgYXZhaWxhYmxlIGR1cmluZ1xuICAgICAgICAvLyBvbmxvYWQsIHNvIGNvbnRpbnVlIHRvIHRyeSBhbmQgZGVmaW5lIHRoZSBsYW5ndWFnZSB1bnRpbCBpdCBpcy5cbiAgICAgICAgY29uc3Qgc2V0dXBJbnRlcnZhbCA9IHNldEludGVydmFsKCgpID0+IHtcbiAgICAgICAgICAgIGlmIChDb2RlTWlycm9yICYmIENvZGVNaXJyb3IuZGVmaW5lU2ltcGxlTW9kZSkge1xuICAgICAgICAgICAgICAgIENvZGVNaXJyb3IuZGVmaW5lU2ltcGxlTW9kZShcImdkc2NyaXB0XCIsIHtcbiAgICAgICAgICAgICAgICAgICAgc3RhcnQ6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXGIweFswLTlhLWZdK1xcYi9pLCB0b2tlbjogXCJudW1iZXJcIiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcYi0/XFxkK1xcYi8sIHRva2VuOiBcIm51bWJlclwiIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvIy4rLywgdG9rZW46ICdjb21tZW50JyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xccyooQG9ucmVhZHl8QGV4cG9ydClcXGIvLCB0b2tlbjogJ2tleXdvcmQnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFxiKD86YW5kfGFzfGFzc2VydHxhd2FpdHxicmVha3xicmVha3BvaW50fGNvbnN0fGNvbnRpbnVlfGVsaWZ8ZWxzZXxlbnVtfGZvcnxpZnxpbnxpc3xtYXN0ZXJ8bWFzdGVyc3luY3xtYXRjaHxub3R8bnVsbHxvcnxwYXNzfHByZWxvYWR8cHVwcGV0fHB1cHBldHN5bmN8cmVtb3RlfHJlbW90ZXN5bmN8cmV0dXJufHNlbGZ8c2V0Z2V0fHN0YXRpY3x0b29sfHZhcnx3aGlsZXx5aWVsZClcXGIvLCB0b2tlbjogJ2tleXdvcmQnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvWygpXFxbXFxde30sXS8sIHRva2VuOiBcIm1ldGFcIiB9LFxuXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBUaGUgd29yZHMgZm9sbG93aW5nIGZ1bmMsIGNsYXNzX25hbWUgYW5kIGNsYXNzIHNob3VsZCBiZSBoaWdobGlnaHRlZCBhcyBhdHRyaWJ1dGVzLFxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gc28gcHVzaCBvbnRvIHRoZSBkZWZpbml0aW9uIHN0YWNrXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFxiKGZ1bmN8Y2xhc3NfbmFtZXxjbGFzc3xleHRlbmRzfHNpZ25hbClcXGIvLCB0b2tlbjogXCJrZXl3b3JkXCIsIHB1c2g6IFwiZGVmaW5pdGlvblwiIH0sXG5cbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9APyg/OihcInwnKSg/Oig/IVxcMSlbXlxcblxcXFxdfFxcXFxbXFxzXFxTXSkqXFwxKD8hXCJ8Jyl8XCJcIlwiKD86W15cXFxcXXxcXFxcW1xcc1xcU10pKj9cIlwiXCIpLywgdG9rZW46IFwic3RyaW5nXCIgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC9cXCRbXFx3XFwvXStcXGIvLCB0b2tlbjogJ3ZhcmlhYmxlJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcOltcXHNdKiQvLCB0b2tlbjogJ29wZXJhdG9yJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcOlsgXSovLCB0b2tlbjogJ21ldGEnLCBwdXNoOiAndmFyX3R5cGUnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFwtPlsgXSovLCB0b2tlbjogJ29wZXJhdG9yJywgcHVzaDogJ2RlZmluaXRpb24nIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFwrfFxcKnwtfFxcL3w6PXw+fDx8XFxefCZ8XFx8fCV8fnw9LywgdG9rZW46IFwib3BlcmF0b3JcIiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWdleDogL1xcYig/OmZhbHNlfHRydWUpXFxiLywgdG9rZW46ICdudW1iZXInIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvXFxiW0EtWl1bQS1aX1xcZF0qXFxiLywgdG9rZW46ICdvcGVyYXRvcicgfSxcbiAgICAgICAgICAgICAgICAgICAgXSxcbiAgICAgICAgICAgICAgICAgICAgdmFyX3R5cGU6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVnZXg6IC8oXFx3KykvLCB0b2tlbjogJ2F0dHJpYnV0ZScsIHBvcDogdHJ1ZSB9LFxuICAgICAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgICAgICAgICBkZWZpbml0aW9uOiBbXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZ2V4OiAvKFxcdyspLywgdG9rZW46IFwiYXR0cmlidXRlXCIsIHBvcDogdHJ1ZSB9XG4gICAgICAgICAgICAgICAgICAgIF1cbiAgICAgICAgICAgICAgICB9KVxuXG4gICAgICAgICAgICAgICAgc2VsZi5hcHAud29ya3NwYWNlLml0ZXJhdGVBbGxMZWF2ZXMoKGxlYWYpID0+IHtcbiAgICAgICAgICAgICAgICAgICAgbGVhZi5yZWJ1aWxkVmlldygpO1xuICAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgICBjbGVhckludGVydmFsKHNldHVwSW50ZXJ2YWwpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9LCAxMDApO1xuICAgIH1cblxuICAgIG9udW5sb2FkKCkge1xuICAgICAgICBkZWxldGUgQ29kZU1pcnJvci5tb2Rlc1snZ2RzY3JpcHQnXTtcbiAgICB9XG59XG4iXSwibmFtZXMiOlsiUGx1Z2luIl0sIm1hcHBpbmdzIjoiOzs7O0FBR2UsTUFBTSxvQkFBb0IsU0FBU0EsZUFBTSxDQUFDO0FBQ3pELElBQUksTUFBTSxHQUFHO0FBQ2IsUUFBUSxJQUFJLElBQUksR0FBRyxJQUFJLENBQUM7QUFDeEI7QUFDQTtBQUNBO0FBQ0EsUUFBUSxNQUFNLGFBQWEsR0FBRyxXQUFXLENBQUMsTUFBTTtBQUNoRCxZQUFZLElBQUksVUFBVSxJQUFJLFVBQVUsQ0FBQyxnQkFBZ0IsRUFBRTtBQUMzRCxnQkFBZ0IsVUFBVSxDQUFDLGdCQUFnQixDQUFDLFVBQVUsRUFBRTtBQUN4RCxvQkFBb0IsS0FBSyxFQUFFO0FBQzNCLHdCQUF3QixFQUFFLEtBQUssRUFBRSxrQkFBa0IsRUFBRSxLQUFLLEVBQUUsUUFBUSxFQUFFO0FBQ3RFLHdCQUF3QixFQUFFLEtBQUssRUFBRSxXQUFXLEVBQUUsS0FBSyxFQUFFLFFBQVEsRUFBRTtBQUMvRCx3QkFBd0IsRUFBRSxLQUFLLEVBQUUsS0FBSyxFQUFFLEtBQUssRUFBRSxTQUFTLEVBQUU7QUFDMUQsd0JBQXdCLEVBQUUsS0FBSyxFQUFFLHlCQUF5QixFQUFFLEtBQUssRUFBRSxTQUFTLEVBQUU7QUFDOUUsd0JBQXdCLEVBQUUsS0FBSyxFQUFFLDZOQUE2TixFQUFFLEtBQUssRUFBRSxTQUFTLEVBQUU7QUFDbFIsd0JBQXdCLEVBQUUsS0FBSyxFQUFFLGFBQWEsRUFBRSxLQUFLLEVBQUUsTUFBTSxFQUFFO0FBQy9EO0FBQ0E7QUFDQTtBQUNBLHdCQUF3QixFQUFFLEtBQUssRUFBRSw0Q0FBNEMsRUFBRSxLQUFLLEVBQUUsU0FBUyxFQUFFLElBQUksRUFBRSxZQUFZLEVBQUU7QUFDckg7QUFDQSx3QkFBd0IsRUFBRSxLQUFLLEVBQUUsNEVBQTRFLEVBQUUsS0FBSyxFQUFFLFFBQVEsRUFBRTtBQUNoSSx3QkFBd0IsRUFBRSxLQUFLLEVBQUUsYUFBYSxFQUFFLEtBQUssRUFBRSxVQUFVLEVBQUU7QUFDbkUsd0JBQXdCLEVBQUUsS0FBSyxFQUFFLFVBQVUsRUFBRSxLQUFLLEVBQUUsVUFBVSxFQUFFO0FBQ2hFLHdCQUF3QixFQUFFLEtBQUssRUFBRSxRQUFRLEVBQUUsS0FBSyxFQUFFLE1BQU0sRUFBRSxJQUFJLEVBQUUsVUFBVSxFQUFFO0FBQzVFLHdCQUF3QixFQUFFLEtBQUssRUFBRSxTQUFTLEVBQUUsS0FBSyxFQUFFLFVBQVUsRUFBRSxJQUFJLEVBQUUsWUFBWSxFQUFFO0FBQ25GLHdCQUF3QixFQUFFLEtBQUssRUFBRSxpQ0FBaUMsRUFBRSxLQUFLLEVBQUUsVUFBVSxFQUFFO0FBQ3ZGLHdCQUF3QixFQUFFLEtBQUssRUFBRSxvQkFBb0IsRUFBRSxLQUFLLEVBQUUsUUFBUSxFQUFFO0FBQ3hFLHdCQUF3QixFQUFFLEtBQUssRUFBRSxvQkFBb0IsRUFBRSxLQUFLLEVBQUUsVUFBVSxFQUFFO0FBQzFFLHFCQUFxQjtBQUNyQixvQkFBb0IsUUFBUSxFQUFFO0FBQzlCLHdCQUF3QixFQUFFLEtBQUssRUFBRSxPQUFPLEVBQUUsS0FBSyxFQUFFLFdBQVcsRUFBRSxHQUFHLEVBQUUsSUFBSSxFQUFFO0FBQ3pFLHFCQUFxQjtBQUNyQixvQkFBb0IsVUFBVSxFQUFFO0FBQ2hDLHdCQUF3QixFQUFFLEtBQUssRUFBRSxPQUFPLEVBQUUsS0FBSyxFQUFFLFdBQVcsRUFBRSxHQUFHLEVBQUUsSUFBSSxFQUFFO0FBQ3pFLHFCQUFxQjtBQUNyQixpQkFBaUIsRUFBQztBQUNsQjtBQUNBLGdCQUFnQixJQUFJLENBQUMsR0FBRyxDQUFDLFNBQVMsQ0FBQyxnQkFBZ0IsQ0FBQyxDQUFDLElBQUksS0FBSztBQUM5RCxvQkFBb0IsSUFBSSxDQUFDLFdBQVcsRUFBRSxDQUFDO0FBQ3ZDLGtCQUFrQixDQUFDLENBQUM7QUFDcEI7QUFDQSxpQkFBaUIsYUFBYSxDQUFDLGFBQWEsQ0FBQyxDQUFDO0FBQzlDLGFBQWE7QUFDYixTQUFTLEVBQUUsR0FBRyxDQUFDLENBQUM7QUFDaEIsS0FBSztBQUNMO0FBQ0EsSUFBSSxRQUFRLEdBQUc7QUFDZixRQUFRLE9BQU8sVUFBVSxDQUFDLEtBQUssQ0FBQyxVQUFVLENBQUMsQ0FBQztBQUM1QyxLQUFLO0FBQ0w7Ozs7In0=
