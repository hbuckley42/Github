CREATE OR REPLACE PACKAGE test_report AS


 -- H.Buckley - June 2014

  g_sccsid CONSTANT VARCHAR2(2000):='"$Revision:   1.0  $"';

--</GLOBVAR>
--
-----------------------------------------------------------------------------
--
--<PROC NAME="GET_VERSION">
-- This function returns the current SCCS version
FUNCTION get_version RETURN varchar2;
--</PROC>
--
-----------------------------------------------------------------------------
--
--<PROC NAME="GET_BODY_VERSION">
-- This function returns the current SCCS version of the package body
FUNCTION get_body_version RETURN varchar2;
--</PROC>
-----------------------------------------------------------------------------
--
--<PROC NAME="REP_PARAMS">
-- This function returns the current SCCS version of the package body
PROCEDURE rep_params;
--</PROC>
-----------------------------------------------------------------------------
--
--<PROC NAME="REPORT">
-- This function returns the current SCCS version of the package body
PROCEDURE report (pi_report_type varchar2  ) ;
--
-----------------------------------------------------------------------------
--
END test_report;
/

CREATE OR REPLACE PACKAGE BODY test_report AS
--
-- H.Buckley - June 2014
-- 
 
  g_body_sccsid  CONSTANT varchar2(2000) :='""';
--
 g_package_name    CONSTANT  varchar2(30)   := 'test_report';
-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
--
FUNCTION get_version RETURN varchar2 IS
BEGIN
   RETURN g_sccsid;
END get_version;
--
-----------------------------------------------------------------------------
--
FUNCTION get_body_version RETURN varchar2 IS
BEGIN
   RETURN g_body_sccsid;
END get_body_version;
--
-----------------------------------------------------------------------------
PROCEDURE rep_params 
IS
   c_this_module  CONSTANT hig_modules.hmo_module%TYPE := 'NTH0001';
   c_module_title CONSTANT hig_modules.hmo_title%TYPE  := 'Bus Stop Asset XML Extract';

   l_tab_value    nm3type.tab_varchar30;
   l_tab_prompt   nm3type.tab_varchar30;
   l_checked      varchar2(8) := ' CHECKED';

BEGIN

  l_tab_value(1)  := 'NTH0001';
  l_tab_prompt(1) := 'Bus Stop XML Asset Extract';
  
  nm3web.head(p_close_head => TRUE
             ,p_title      => c_module_title);
  htp.bodyopen;
  nm3web.module_startup(c_this_module);

--/*
  htp.p('<DIV ALIGN="CENTER">');


  htp.header(nsize   => 1
            ,cheader => c_module_title
            ,calign  => 'center');

--*/

   htp.tableopen(calign => 'center');
  --open form to submit params to results procedure
   htp.formopen(curl => 'x_northants_xml.XMLDataExtract');

   htp.p('<TR>');
   htp.p('<TD COLSPAN=2>'||htf.hr||'</TD>');
   htp.p('</TR>');
   htp.p('<TR>');
   htp.p('<TD COLSPAN=2 ALIGN=CENTER>');
   htp.tableopen;
   htp.tablerowopen;
   htp.tableheader('Press "Continue" and the file will take a moment to create.', cattributes=>'COLSPAN=2');
   htp.tablerowclose;
   --
   --FOR i IN 1..l_tab_value.COUNT
   --LOOP
   --   htp.tablerowopen(cattributes=>'ALIGN=CENTER');
   --   htp.tabledata(l_tab_prompt(i));
         --htp.p('<TD><INPUT TYPE="HIDDEN" NAME="pi_report_type" VALUE="'||l_tab_value(i)||'"></TD>');
   --         htp.p('<TD><INPUT TYPE=RADIO NAME="pi_report_type" VALUE="'||l_tab_value(i)||'"'||l_checked||'></TD>');
   --      l_checked := NULL;
   --      htp.tablerowclose;
   --END LOOP;
   htp.tableclose;
      
   --
   htp.p('</TD>');
   htp.p('<TR>');
   htp.p('<TD COLSPAN=2>'||htf.hr||'</TD>');
   htp.p('</TR>');
   htp.p('<TR>');
   
  --button that submits the form,
  htp.tablerowopen(calign=> 'center');
  htp.p('<TD colspan="2">');
  htp.formsubmit(cvalue => 'Press [Enter] to Start File Extraction Process');
  htp.p('</TD>');
  htp.tablerowclose;

  htp.formclose;
                      
  htp.tableclose;

  nm3web.CLOSE;
  nm_debug.proc_end(p_package_name   => g_package_name
                   ,p_procedure_name => 'rep_params');

EXCEPTION
  WHEN nm3web.g_you_should_not_be_here
  THEN
    raise;
  WHEN others
  THEN
  nm_debug.debug('error');
    nm3web.failure(pi_error => SQLERRM);
END rep_params ;
--
-----------------------------------------------------------------------------
--
PROCEDURE report (pi_report_type varchar2  ) IS
   c_this_module  CONSTANT hig_modules.hmo_module%TYPE := 'ZSTP_REP';
   c_module_title CONSTANT hig_modules.hmo_title%TYPE  := hig.get_module_title(c_this_module);

  c_nl varchar2(1) := CHR(10);
  l_qry nm3type.max_varchar2;

  i number:=0;
  l number;

  l_rec_nuf               nm_upload_files%ROWTYPE;
  c_mime_type    CONSTANT varchar2(30) := 'application/STEP';
  c_sysdate      CONSTANT date         := SYSDATE;
  c_content_type CONSTANT varchar2(4)  := 'BLOB';
  c_dad_charset  CONSTANT varchar2(5)  := 'ascii';
  v_clob clob;
  v_tmp_clob clob;
 

  l_tab        nm3type.tab_varchar32767;
  l_tab_value  nm3type.tab_varchar30;
  l_tab_prompt nm3type.tab_varchar30;
  
  
  l_report_ea varchar2(200);
  
  vCursor  sys_refcursor;

  csql     varchar2(20000);
  v_row    varchar2(20000);
  l_title  varchar(200);
  l_header varchar2(20000);
  l_table  varchar2(30);

BEGIN

  nm_debug.debug('in the second procedure');
  nm_debug.proc_start(p_package_name   => g_package_name
                     ,p_procedure_name => 'report');

  nm3web.head(p_close_head => TRUE
             ,p_title      => c_module_title);
  htp.bodyopen;
  
  nm3web.module_startup(pi_module => c_this_module);

  l_rec_nuf.mime_type              := c_mime_type;
  l_rec_nuf.dad_charset            := c_dad_charset;
  l_rec_nuf.last_updated           := c_sysdate;
  l_rec_nuf.content_type           := c_content_type;
  l_rec_nuf.doc_size               := 0;
  l_rec_nuf.name                   := 'DTIMS_EXTRACT_'||to_char(sysdate,'DD-MON-YYYY:HH24:MI:SS')||'.csv'  ;   
    
    case 
    when pi_report_type = 'DTIMS'
    then
            l_title        :=  'DTIMS Extract';
            l_table        := 'XRTA_DTIMS_V2';
            l_rec_nuf.name := 'DTIMS_EXTRACT_'||to_char(sysdate,'DD-MON-YYYY:HH24:MI:SS')||'.csv'  ;          
    end case;                                                                   

    csql :=   'select ';
    for n in 
        (select column_name c  from  dba_tab_columns
         where table_name = upper(l_table)
         order by column_id)
    loop
       l_header := l_header || n.c || '|' ;
       csql  := csql || n.c  || '||''|''||';
    end loop; 

    l        :=  length(csql);
    l_header := substr(l_header, 1, length(l_header) - 1);
    csql     := substr( csql, 1, l - 7 ) || ' from ' || l_table;
    l_qry    := 'Select ' || l_header || ' from ' || l_table; 

    select  l_title
    into    v_row
    from    dual;
    
    l_tab(l_tab.count+1):= v_row||chr(13)||chr(10);  --Changed from a LF(10) to a CRLF as requested
    l_rec_nuf.doc_size  := l_rec_nuf.doc_size+length(l_tab(l_tab.count));
  
    select '' || l_header || ''       
       into v_row
    from dual;
    
    
    l_tab(l_tab.count+1):= v_row||chr(13)||chr(10);  --Changed from a LF(10) to a CRLF as requested
    l_rec_nuf.doc_size  := l_rec_nuf.doc_size+length(l_tab(l_tab.count));
       
    htp.p('<div align="center">');

    htp.p('<h2> ' || l_title || '</h2>');
 
    -- htp.p(pi_report_type); debug
 
    htp.p('<table> <tr> <td> <h3>  <a href=docs/'||l_rec_nuf.name||'>
     <b> Download </b> </a> as a CSV file </h3> </td><td></tr>
     <tr><td><A HREF="nm3web.run_module?pi_module=DTIMS_REP"> Return to the  Report Parameters </A></td></tr></table>');
    --    htp.p('</TD>');
    --  htp.tablerowclose;

  htp.p(' <p> ');

  --htp.p('l_qry = ' ||l_qry || '<p>'); -- debug
  -- htp.p('csql = ' ||csql ); -- debug
  -- csql:= 'select * from dual'; -- debug
  -- we don't want this for ZSTP
  --  nm3web.htp_tab_varchar(p_tab_vc => dm3query.execute_query_sql_tab(p_sql => l_qry));
  htp.p('</div>');
  nm3web.CLOSE;
  
  open vCursor for csql ;        
    loop
        fetch vCursor into v_row;
        exit when vCursor%notfound;
       l_tab(l_tab.count+1):= v_row||chr(13)||chr(10);  --Changed from a LF(10) to a CRLF as requested
       l_rec_nuf.doc_size  := l_rec_nuf.doc_size+length(l_tab(l_tab.count));
       
    end loop;


        for a in  1 .. l_tab.count
        loop
            v_tmp_clob :=   l_tab(a);
            v_clob := v_clob || v_tmp_clob;
        end loop;

        l_rec_nuf.blob_content           := nm3clob.clob_to_blob(v_clob);

        delete from nm_upload_files
        where name= l_rec_nuf.name;

         nm3ins.ins_nuf (l_rec_nuf);
         COMMIT;

nm_debug.proc_end(p_package_name   => g_package_name
                   ,p_procedure_name => 'report');


EXCEPTION
  WHEN others
  THEN
    nm3web.failure(pi_error => SQLERRM);
--    nm3web.failure(pi_error => l_qry);
END report;
--

END test_report;
/
