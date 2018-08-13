$(function() {
	var customCSS = '.info,table.table-striped{width:100%}input#toggle{display:none;visibility:hidden}label#primary-links{display:block;padding:.3em;text-align:left}#toggle:checked~label::before,label#primary-links::before{font-family:Consolas,monaco,monospace;font-weight:700;content:attr(data-before);position:relative;top:5px}#expand{height:0;overflow:hidden;transition:height .5s}#toggle:checked~#expand{height:auto}.table-striped tr:nth-child(even){background:#FFC0C0}.table-striped tr:nth-child(odd){background:#FFEBEB}.info{position:relative;top:-28px;padding-left:32px;height:20px}.label_aviso,.label_erro,.label_ok{position:relative;top:-12px;padding-left:10px;width:20px;height:20px}.label_ok{content:url(../images/ok.png)}.label_aviso{content:url(../images/aviso.png)}.label_erro{content:url(../images/erro.png)}#primary-links{background:url(../images/menubg.gif) repeat-x #FF9148;height:20px}';

	$('head').append('<style>' + customCSS + '</style>');
	var nosHeader = $('.status > table.status > tbody > tr > td:last-child').filter(function(a,b) { return b.innerText.indexOf('header←') > -1; } );
	if(nosHeader != null && nosHeader.length > 0) {
		nosHeader.each(function(idx, node) {
			var $node = $(node);
			var conteudo = $node.text();
			$node.text('');
			var splited = conteudo.split('←');
			var procedure = splited.length > 1 ? splited[1] : "";
			var label = splited.length > 2 ? splited[2] : "";
			var status = splited.length > 3 ? splited[3] : "";
			var returnedMessage = splited.length > 4 ? splited[4] : "";
			var $tableTD = $('<table class="table table-striped" id="' + procedure + "_" + idx + '">\
								<thead>\
									<tr>\
										<th>\
											<input id="toggle" type="checkbox" data="' + idx +'">\
											<label id="primary-links" class="my_toggle" for="toggle" data-before="+">\
												<div class="' + label + '"/>\
												<span class="info">' + status + ': SQL Query returned: ' + returnedMessage + ' for stored procedure: ' + procedure + '</span>\
											</label>\
										</th>\
									</tr>\
								</thead>\
								<tbody style="display:none" />\
							 </table>');

			var maxCols = 0
			var rows = splited.length > 5 ? splited[5] : "";
			var trs = rows.split('∟');
			trs.forEach(function(item, idx) {
				if(item.trim()) {
					var totalCols = 0;
					var $tr = $('<tr/>');
					var tds = item.split('↔');
					tds.forEach(function(item, idx) {
						if(item.trim()) {
							var $td = $('<td/>');
							$td.text(item);
							$tr.append($td);
							++totalCols;
						}
					});
					maxCols = totalCols > maxCols ? totalCols : maxCols;
					$tableTD.find('tbody').append($tr);
				}
			});
			$tableTD.find('thead > tr > th').attr('colspan', maxCols);
			$node.append($tableTD);
		});

	}
	var $input = $(".my_toggle");
	$input.click(function(evt) {
		var $currToggle = $(evt.currentTarget);
		var $parentTable = $currToggle.parents('.table-striped');
		if ($parentTable.find("tbody").is(":visible") == true) {
			$parentTable.find("tbody").hide();
			$currToggle.attr('data-before','+');
		} else {
			$parentTable.find("tbody").show();
			$currToggle.attr('data-before','-');
		}
	});
})

