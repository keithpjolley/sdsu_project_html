  <script type="text/javascript" charset="utf-8">
    /* Define two custom functions (asc and desc) for string sorting */
    jQuery.fn.dataTableExt.oSort['string-case-asc']  = function(x,y) {
      return ((x < y) ? -1 : ((x > y) ?  1 : 0));
    };
    jQuery.fn.dataTableExt.oSort['string-case-desc'] = function(x,y) {
      return ((x < y) ?  1 : ((x > y) ? -1 : 0));
    };
//    $(document).ready(function() {
//      /* Build the DataTable with third column using our custom sort functions */
//      $('#example').dataTable( {
//        "aaSorting": [ [0,'asc'], [1,'asc'] ],
//        "aoColumnDefs": [
//          { "sType": 'string-case', "aTargets": [ 2 ] }
//        ]
//      });
//    });
    $(document).ready(function() {
      $('#example').dataTable( {
        "bProcessing": true,
        "sAjaxSource": "__JSON_FILE__"
      });
    });
  </script>
