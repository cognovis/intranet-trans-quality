# /packages/intranet-trans-quality/www/quality-report

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
} {
    task_id:integer,notnull
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "Quality"
set context_bar [ad_context_bar_ws $page_title]

if { [info exist group_id] && [info exist task_id] } {
    db_0or1row task {
select
	t.*
from
	im_tasks t
where
	project_id = :group_id
	and task_id = :task_id
    }
}


set error_list_sql "
select
        qe.*,
	im_category_from_id(qe.quality_category_id) as category
from
        im_trans_quality_entries qe,
        im_trans_quality_reports qr	
where
        qe.report_id = qr.report_id
        and qr.task_id = :task_id"


set table_bottom_html "
<table border=0>
<tr align=left valign=middle>
  <td colspan=2  class=roweven><strong>Error Category</strong></td>
  <td  class=roweven><strong>Minor</strong></td>
  <td  class=roweven><strong>Mayor</strong></td>
  <td  class=roweven><strong>Critical</strong></td>
  <td>&nbsp;</td>
  <td class=roweven><strong>Total</strong></td>
  <td class=roweven><strong>Max. allowed</strong></td>
</tr>"

set total 0
db_foreach error_list $error_list_sql {
    set total_errors [expr [expr $minor_errors * 1] + [expr $major_errors * 5] + [expr $critical_errors * 10]]
    set total [expr $total + $total_errors]
    append table_bottom_html "
<tr align=left valign=middle>
<td colspan=2>$category</td>
<td><input name=$category.minor type=text size=10 value=$minor_errors disabled></td>
<td><input name=$category.major type=text size=10 value=$major_errors disabled></td>
<td><input name=$category.critical type=text size=10 value=$critical_errors disabled></td>
<td>&nbsp;</td>
<td><input name=$category.total type=text size=10 value=$total_errors disabled></td>
<td><input type=text size=10 disabled></td> 
</tr>"    
}
append table_bottom_html "
<tr>
<td colspan=5></td>
<td class=roweven><strong>Total</strong></td>
<td><input name=total type=text size=10 value=$total disabled></td>
<td></td>
</tr></table>"



db_1row task_report {
select
        t.task_name,
        u.user_name as translator_name,
        t.task_units as words,
        c.group_name as customer_name,
        p.manager_name,
        im_category_from_id (t.source_language_id) as source_language,
        im_category_from_id (t.target_language_id) as target_language
from
        im_tasks t,
        ( select g.group_name
         from   user_groups g,
                im_projects p,
                im_tasks t
         where  g.group_id = p.customer_id
                and p.group_id = t.project_id
                and t.task_id = :task_id
        ) c,
        ( select u.first_names||' '||u.last_name as manager_name
         from   im_projects p,
                users u,
                im_tasks t
         where  u.user_id = p.project_lead_id
                and p.group_id = t.project_id
                and t.task_id = :task_id
        ) p,
        ( select u.first_names||' '||u.last_name as user_name
         from   users u,
                im_tasks t
         where  u.user_id = t.trans_id
                and t.task_id = :task_id
        ) u
where
        t.task_id = :task_id
}

db_1row task_quality {
select
	qr.*, 
	n.reviwer_name
from
	im_trans_quality_reports qr,
	(select u.first_names||' '||u.last_name as reviwer_name
	 from users u, im_trans_quality_reports qr
	 where u.user_id = qr.reviewer_id and qr.task_id = :task_id
	) n
where
	task_id = :task_id
}

set max_error [expr [expr $sample_size * $allowed_error_percentage] / 100] 



set table_header_html "
<table border=0 cellspacing=0 cellpadding=0>
  <tr class=roweven>
    <td><strong>Source Language</strong></td>
    <td><input name=source_language type=text [export_form_value source_language] disabled></td>
    <td colspan=2></td>
    <td ><div align=right><strong>Date</strong></div></td>
    <td><input name=date type=text value=$report_date disabled></td>
    <td align=right><strong>Result </strong></td><td valign=top><div id='Result' style='position:absolute; width:84px; height:10px; color: \#FF0000; background: \#FFFFFF; border: 2px solid \#000000; padding: 3px;'>
      <strong><center>$total</center></strong>
      </div>------
   </td>

  </tr>
  <tr align=left valign=top class=roweven>
    <td> <strong>Target Language</strong></td>
    <td><input name=target_language type=text [export_form_value target_language] disabled></td>
    <td colspan=2>&nbsp; </td>
    <td><div align=right><strong>Reviewer Name</strong></div></td>
    <td><input name=reviwer_name type=text [export_form_value reviwer_name] disabled></td>
    <td colspan=2 align=right valign=bottom><strong>Comments</strong></td>
  </tr>
  <tr align=left valign=top>
     <td colspan=6>&nbsp;</td>
     <td rowspan=7 colspan=2><textarea name=comment cols=25 rows=10></textarea></td>
  </tr>
  <tr align=left valign=middle>
    <td class=roweven><strong>Client Name </strong></td>
    <td class=roweven> <input name=customer_name type=text [export_form_value customer_name] disabled></td>
    <td colspan=2>&nbsp;</td>
    <td class=roweven><strong>Project Number</strong></td>
    <td class=roweven><input name=project_number type=text disabled></td>
  </tr>
  <tr align=left valign=middle  >
    <td class=roweven><strong>Translator Name</strong></td>
    <td class=roweven><input name=trans_name type=text [export_form_value translator_name] disabled></td>
    <td colspan=2>&nbsp;</td>
    <td class=roweven><strong>Project Manager</strong></td>
    <td class=roweven><input name=manager_name type=text [export_form_value manager_name] disabled></td>
  </tr>
  <tr align=left valign=middle  >
    <td colspan=6>&nbsp;</td>
  </tr>
  <tr>
    <td colspan=4></td>
    <td class=roweven><strong>critical</strong></td>
    <td><input type=text name=critical></td>
  </tr>
  <tr align=left valign=middle  >
    <td class=roweven><strong>Sample size</strong></td>
    <td class=roweven><input name=sample_size type=text [export_form_value sample_size] disabled></td>
    <td colspan=2 >&nbsp;</td>
    <td class=roweven><strong>Major</strong></td>
    <td><input type=text name=major</td>
  </tr>
  <tr>
    <td class=roweven><strong>Max. errors allowed</strong></td>
    <td class=roweven><input type=text name=max_erros value='$max_error' disabled></td>
    <td colspan=2></td>
    <td class=roweven><strong>Minor</strong></td>
    <td><input type=text name=minor></td>
  </tr>
</table>
"

set page_body "
$table_header_html
<br>
$table_bottom_html
"
db_release_unused_handles

doc_return  200 text/html [im_return_template]
