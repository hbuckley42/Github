CREATE OR REPLACE PACKAGE BODY X_NORTHANTS_XML AS
/******************************************************************************
   NAME:       X_NORTHANTS_XML
   PURPOSE:    This program will generate a text file which will contain 
               bus stop information. This information will be defined within
               assets and this script will make use of the specfic asset type
               view.

               Output File: This routine needs to produce a file to a specified
                            Oracle Directory AND it must also put the contents
                            into nm_upload_files and in this way we can elect to
                            either guide the user to the file or have the file 
                            automatically downloaded to the client.

               1. Query data back
               2. Add fomatted data together with tags to array
               3. Output array to Oracle Directory
               4. Place array contents into nm_upload_files
               5. Provide output to user.
 
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        01/03/2011  H.Buckley        1. Created this package.
   1.1        30/06/2014  H.Buckley        2. Development for initial package.


XML Tags : StopPoints,AtcoCode,NaptanCode,Descriptor,CommonName,Landmark.Street

I have thought of running this module as a gri module with 1 parameter but the 
problem with running it as a pre-process is that the use does not knw when the 
module has finished execution. A better way would be to create the module as a 
GRI module in the sam way but have an SQL file execute the code and in this way
log information is then related to the user indicating when the pocess is complete.
A thrd 
Generated Output
================
   This modue is not going to write an output file to the filesystem, it is
going to place the contents of the outut into nm_upload_files and it is then
going to provide a browser interface ( webform ) to the user so that the user
can thn download the file locally.

******************************************************************************/

  dbg                   BOOLEAN     :=false;
  v_module              VARCHAR2(8) :='NTH0001';
  Now                   varchar2(20):=to_char(sysdate,'RRRR-MM-DD')||'T'||to_char(sysdate,'hh:mm:ss');
  Global_Date_Format    varchar2(25):='DD-MON-YYYY hh24:mi:ss';
  NowStr                varchar2(25):=to_char(sysdate,Global_Date_Format);
  --
  -- Constants .....
  --
  MAXRECLEN          INTEGER        :=500;
  gGridType          varchar2(4)    :='UKOS';
  gFileType          varchar2(3)    :='xml';
  gModification      varchar2(10)   :='new';
  gModification2     varchar2(10)   :='revise';
  gRevision          integer        :=0;
  gRevision2         integer        :=2;
  gStatus            varchar2(10)   :='inactive';
  gSchema            number         :=2.1;
  gAdminRef          varchar2(4)    :='093';
  --gFilename          varchar2(255)  :=replace('NaPTAN300'||'_'||to_char(sysdate,'ddmmyy:hh24:mi:ss')||'.'||gFileType,':');
  gFilename          varchar2(255)  :='NaPTAN300'||'.'||gFileType;
  --
  -- *********************
  -- Type Declaration
  -- *********************
  -- Here we need to make use of the standard asset view but
  -- we must also ensure that we set the effective date back 
  -- since the view works on the effective date.
  cursor GetBusStopDetails
  is select *
     from   v_nm_ti;
     --where  rownum<=10; -- Include only OPEN stops.ops
     --where  iit_end_date  is null;
     --and    notes is not null
     --order by <whatever condition>;

  type output_rec is table of varchar2(500) index by binary_integer;
  --output_tab     output_rec;
  output_tab     nm3type.tab_varchar32767;
  l_tab          nm3type.tab_varchar32767; 
  l_rec_nuf      nm_upload_files%rowtype;
  -- 
  outrecseq      integer:=1;
  --
  v_filename     VARCHAR2(500);  
  --
  -- *****************************************************************************
  -- Get the package version
  -- *****************************************************************************
FUNCTION get_version RETURN varchar2 IS
BEGIN
   RETURN g_body_sccsid;
END get_version;
  -- *****************************************************************************
  -- Get the package BODY version
  -- *****************************************************************************
FUNCTION get_body_version RETURN varchar2 IS
BEGIN
   RETURN g_body_sccsid;
END get_body_version;
--
--
PROCEDURE download_file_to_client (pi_name    IN varchar2 ) 
IS
l_nuf nm_upload_files%ROWTYPE:=nm3get.get_nuf(pi_name);
BEGIN
   htp.flush;
   htp.init;
   owa_util.mime_header('application/octet-stream',FALSE);
   htp.p('Content-length: ' ||to_char(l_rec_nuf.doc_size));
   htp.p('Content-disposition:attachment; filename="' || pi_name||'"');
   htp.p('Set-Cooke: fileDownload=true path=/');
   owa_util.http_header_close;
   wpg_docload.download_file(l_nuf.blob_content);
END download_file_to_client;
-- *****************************************************************************
-- This procedure should provide the user with the facility to download
-- data defined within the FMS GL Data Extrac file format.
-- *****************************************************************************
Procedure XMLDataExtract
IS
  fn VARCHAR2(30):='{XMLDataExtract}';
  -- table type to store buffer output from cursors before outputting contents to a file
  TYPE t1 IS TABLE OF VARCHAR2(500)
  INDEX BY BINARY_INTEGER;
--
  cursor_recs t1;
  /* cursor definitions */
  --
  Now                      date:=trunc(sysdate);
  Current_Date             varchar2(20):=to_char(now,global_date_format);

function inc(in_value in integer) 
return integer
is
  out_value integer;
begin
  out_value:=in_value+1;
  return out_value;
end;

BEGIN
  -- set the effective date back to the start of the century
  -- so that we see ALL assets.
  -- nm3context.set_context('NM3CORE','EFFECTIVE_DATE','01-JAN-1900');
 nm3ctx.Set_Core_Context (p_Attribute =>  'EFFECTIVE_DATE',
                          p_Value     =>  '16-MAY-2013'
                         );
  dbms_output.put_line('Starting: '||to_char(sysdate,'dd-mon-yyyy:hh24:mi:ss'));
  --
  -- *****************************************************
  -- Define the Header for the file.
  -- *****************************************************
  --  
  output_tab(outrecseq):='<?xml version="1.0" encoding="utf-8" ?>';
  outrecseq:=inc(outrecseq);

  output_tab(outrecseq):='<NaPTAN CreationDateTime="'||to_char(sysdate,'RRRR-MM-DD')||'T'||to_char(sysdate,'HH24:MI:SS')||
                        '" ModificationDateTime="'   ||to_char(sysdate,'RRRR-MM-DD')||'T'||to_char(sysdate,'HH24:MI:SS')||
                        '" Modification="'           ||gModification||
                        '" RevisionNumber="'         ||to_char(gRevision)||
                        '" FileName="'               ||gFilename||
                        '" SchemaVersion="'          ||gSchema||
                        '" xmlns="http://www.naptan.org.uk/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.naptan.org.uk/ http://www.naptan.org.uk/schema/2.1/NaPTAN.xsd">';
  outrecseq:=inc(outrecseq);

  -- *****************************************************
  -- THis is the end section of the header.
  -- *****************************************************

  -- This is the beginning of the real asset output
  --
  output_tab(outrecseq):='<StopPoints>';
  outrecseq:=inc(outrecseq);
  --
  for i in GetBusStopDetails
  loop 
     output_tab(outrecseq):='<StopPoint CreationDateTime="'||
                            to_char(i.iit_date_created,'RRRR-MM-DD')||'T'||to_char(i.iit_date_created,'HH24:MI:SS')||'" '||
                            'ModificationDateTime="'||to_char(i.iit_date_modified,'RRRR-MM-DD')||'T'||to_char(i.iit_date_modified,'HH24:MI:SS')||'" '||
     'Modification="'||gModification2||'" RevisionNumber="'||to_char(gRevision2)||'" Status="'||gStatus||'">';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<AtcoCode>'       ||i.ti_atco_code ||'</AtcoCode>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<NaptanCode>'     ||i.naptan_code  ||'</NaptanCode>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Descriptor>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<CommonName>'     ||i.stop_name    ||'</CommonName>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Landmark>'       ||i.stop_name    ||'</Landmark>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Street>'         ||i.street       ||'</Street>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Indicator>'      ||i.identifier   ||'</Indicator>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</Descriptor>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Place>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<NptgLocalityRef>'||i.natgazid       ||'</NptgLocalityRef>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Suburb>'         ||i.natgaz_locality||'</Suburb>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Town>'           ||i.parent_locality||'</Town>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<LocalityCentre></LocalityCentre>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Location>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<GridType>'       ||gGridType  ||'</GridType>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Easting>'        ||i.eastings ||'</Easting>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Northing>'       ||i.northings||'</Northing>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</Location>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</Place>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<StopClassification>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<StopType>'||i.type_of_stop||'</StopType>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<OnStreet>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Bus>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<BusStopType>' ||i.sub_type_of_stop  ||'</BusStopType>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<TimingStatus>'||i.timing_status||'</TimingStatus>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<UnmarkedPoint>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Bearing>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<CompassPoint>'||i.stop_indicator_direction||'</CompassPoint>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</Bearing>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</UnmarkedPoint>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</Bus>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</OnStreet>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</StopClassification>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<AdministrativeAreaRef>'||gAdminRef||'</AdministrativeAreaRef>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='<Notes>'||i.notes||'</Notes>';
     outrecseq:=inc(outrecseq);
     output_tab(outrecseq):='</StopPoint>';
     outrecseq:=inc(outrecseq);
  end loop;
  --
  IF dbg
  THEN dbms_output.put_line('Filename: '||gFilename);
  END IF; 
  --
  l_rec_nuf.name:=gFilename;
  l_rec_nuf.doc_size:=0;
  --
  for i in 1..output_tab.count
  loop --l_tab(l_tab.count+1):=output_tab(i)|| chr(10);
       --l_rec_nuf.doc_size:=nvl(l_rec_nuf.doc_size+length(l_tab(l_tab.count)),0);
       l_tab(i):=output_tab(i)|| chr(10);
       l_rec_nuf.doc_size:=l_rec_nuf.doc_size+length(l_tab(i));
  end loop;

  nm_debug.debug_clob(nm3clob.tab_varchar_to_clob(pi_tab_vc=>l_tab));

  IF dbg
  THEN dbms_output.put_line('Converting to clob.');
  END IF; 

  l_rec_nuf.blob_content:=nm3clob.clob_to_blob(nm3clob.tab_varchar_to_clob(pi_tab_vc=>l_tab));

  IF dbg
  THEN dbms_output.put_line('Removing clob if exists');
  END IF; 
  --
  -- Northamptonshire require a single file name to be used so
  -- because of ths reason we need to ensure that any file that
  -- may exist within the uploads table needs to be deleted.
  --
  delete nm_upload_files
  where  name=l_rec_nuf.name;

  IF   dbg
  THEN dbms_output.put_line('Inserting new clob');
  END IF; 

  l_rec_nuf.last_updated:=sysdate;
  l_rec_nuf.dad_charset :='ascii';
  l_rec_nuf.content_type:='BLOB';
  -- If the mime type is defined as 'application/octet-stream' then
  -- the file will be downloadable by the user , otherwise the file
  -- is displyed in the browser as ASCII text.
  l_rec_nuf.mime_type   :='application/octet-stream';
  nm3ins.ins_nuf(l_rec_nuf);
  dbms_output.put_line('Completed: '||to_char(sysdate,'dd-mon-yyyy:hh24:mi:ss'));
  commit;       
  htp.br;
  htp.print('Records: '||to_char(output_tab.count));
  htp.br;
  htp.print('Charset: '||l_rec_nuf.dad_charset);
  htp.br;
  htp.print('Updated: '||to_char(l_rec_nuf.last_updated,'dd-mon-yyyy:hh24:mi:ss'));
  htp.br;
  htp.print('Size   : '||to_char(l_rec_nuf.doc_size));
  htp.br;
  htp.header(1,'Extract Completed');
  download_file_to_client(gFilename);
  EXCEPTION
     WHEN OTHERS THEN
         dbms_output.put_line(sqlerrm);
END XMLDataExtract;

END X_NORTHANTS_XML; 
/

show errors
