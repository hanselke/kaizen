/*
 * jQuery autoResize (textarea auto-resizer)
 * @copyright James Padolsey http://james.padolsey.com
 * @version 1.04
 */

(function($){
    
    $.fn.autoResize = function(options) {
        
        // Just some abstracted details,
        // to make plugin users happy:
        var settings = $.extend({
            onResize : function(){},
            animate : true,
            animateDuration : 150,
            animateCallback : function(){},
            extraSpace : 20,
            limit: 1000
        }, options);
        
        // Only textarea's auto-resize:
        this.filter('textarea').each(function(){
            
                // Get rid of scrollbars and disable WebKit resizing:
            var textarea = $(this).css({resize:'none','overflow-y':'hidden'}),
            
                // Cache original height, for use later:
                origHeight = textarea.height(),
                
                // Need clone of textarea, hidden off screen:
                clone = (function(){
                    
                    // Properties which may effect space taken up by chracters:
                    var props = ['height','width','lineHeight','textDecoration','letterSpacing'],
                        propOb = {};
                        
                    // Create object of styles to apply:
                    $.each(props, function(i, prop){
                        propOb[prop] = textarea.css(prop);
                    });
                    
                    // Clone the actual textarea removing unique properties
                    // and insert before original textarea:
                    var c = textarea.clone().removeAttr('id').removeAttr('name').css({
                        position: 'absolute',
                        top: 0,
                        left: -9999
                    }).css(propOb).attr('tabIndex','-1')
                    c.appendTo(textarea.parent())
                    return c
					
                })(),
                lastScrollTop = null,
                updateSize = function() {
					
                    // Prepare the clone:
                    clone.height(0).val($(this).val()).scrollTop(10000);
					
                    // Find the height of text:
                    var scrollTop = Math.max(clone.scrollTop(), origHeight) + settings.extraSpace,
                        toChange = $(this).add(clone);
						
                    // Don't do anything if scrollTip hasen't changed:
                    if (lastScrollTop === scrollTop) { return; }
                    lastScrollTop = scrollTop;
					
                    // Check for limit:
                    if ( scrollTop >= settings.limit ) {
                        $(this).css('overflow-y','');
                        return;
                    }
                    // Fire off callback:
                    settings.onResize.call(this);
					
                    // Either animate or directly apply height:
                    settings.animate && textarea.css('display') === 'block' ?
                        toChange.stop().animate({height:scrollTop}, settings.animateDuration, settings.animateCallback)
                        : toChange.height(scrollTop);
                };
            // Updates the width of the clone. (solution for textareas with widths in percent)
            function setCloneWidth(){
                var curatedWidth = Math.floor(parseInt(textarea.width(), 10))
                if (clone.width() !== curatedWidth){
                    clone.css({'width': curatedWidth + 'px'})
                    // Update height of textarea
                    updateSize.call(textarea)
                }
            }
            // Bind namespaced handlers to appropriate events:
            // Update width of twin if browser or textarea is resized (solution for textareas with widths in percent)
            // cannot call unbind() because it would break if there are more than one autoresized textarea in one page
            $(window).bind('resize.dynSiz', setCloneWidth)
            textarea
                .unbind('.dynSiz')
                .bind('resize.dynSiz', setCloneWidth)
                .bind('update.dynSiz keyup.dynSiz keydown.dynSiz change.dynSiz '+
                    //input and paste events are here to catch clipboard pasting
                    'input.dynSiz paste.dynSiz', updateSize);
            //update clone textarea's width after a little delay
            //if the textarea is in an ng:repeat, the width would be around 0 pixel by default
            setTimeout(setCloneWidth, 250)
        });
        
        // Chain:
        return this;
        
    };
    
    
    
})(jQuery);