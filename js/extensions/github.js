//
//  Github Extension (WIP)
//  ~~strike-through~~   ->  <del>strike-through</del>
//

(function(){
    var g = function(converter) {
        return [
            {
              // strike-through
              // NOTE: showdown already replaced "~" with "~T", so we need to adjust accordingly.
              type    : 'lang',
              regex   : '(~T){2}([^~]+)(~T){2}',
              replace : function(match, prefix, content, suffix) {
                  return '<del>' + content + '</del>';
              }
            },
            {
              // ```lang code block
              type    : 'lang',
              regex	  : "(```)([^\n]+)\n([^```]+)(```)",
              replace : function(match, prefix, language, content, suffix) {
                  var code = hljs.highlight(language, content);
                  return '<pre><code>' + code.value + '</code></pre>';
              }
            }
        ];
    };

    // Client-side export
    if (typeof window !== 'undefined' && window.Showdown && window.Showdown.extensions) { 
    	window.Showdown.extensions.g = g; 
    }
    // Server-side export
    if (typeof module !== 'undefined') module.exports = g;
}());