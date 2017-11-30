create or replace PACKAGE BODY FUNC AS

  function get_job_inf(p_type in varchar2,p_job_code in varchar2,p_plant_code in varchar2)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type 
    --
     when 'JOB_NAME' then
      select job_name into l_rtn from mes_job_b_t where job_code = p_job_code and plant_code = p_plant_code;
    --
    when 'DESCRIPTION' then
      --select description into l_rtn from mes_job_b_t where job_code = p_job_code and plant_code = p_plant_code;
      select 'description' into l_rtn from mes_job_b_t where job_code = p_job_code and plant_code = p_plant_code;
     else
      null;
    end case;
    RETURN l_rtn;
  END get_job_inf;

  function get_oprn_inf(p_type in varchar2,p_oprn_code in varchar2,p_plant_code in varchar2)return varchar2 AS
   l_rtn varchar2(100);
  BEGIN
    case p_type
     when 'OPRN_NAME' then
      select oprn_name into l_rtn from mes_oprn_b_t 
        where oprn_code = p_oprn_code and plant_code = p_plant_code;
     else
      null;
    end case;
    RETURN l_rtn;
  END get_oprn_inf;

  function get_plant_inf(p_type in varchar2,p_plant_code in varchar2)return varchar2 AS
   l_rtn varchar2(100);
  BEGIN
    case p_type  
     when 'ERP_PLANT_CODE' then
      select max(erp_plant_code) into l_rtn from mes_plant_b_t where plant_code = p_plant_code;
     when 'PLANT_NAME' then
      select max(plant_name) into l_rtn from mes_plant_b_t where plant_code = p_plant_code;
     else
      null;
    end case;
    RETURN l_rtn;
  END get_plant_inf;

  function get_role_inf(p_type in varchar2,p_role_id in number,p_app_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'ROLE_NAME' then
      select role_name into l_rtn from mes_role_b_t where role_id = p_role_id and app_id = p_app_id;
     when 'ROLE_TYPE' then
      select role_type into l_rtn from mes_role_b_t where role_id = p_role_id and app_id = p_app_id;
     when 'PAGE_ID_ARRAY' then
      select page_id_array into l_rtn from mes_role_b_t where role_id = p_role_id and app_id = p_app_id;
     else
      null;
    end case; 
    RETURN l_rtn;
  END get_role_inf;

  function get_user_inf(p_type in varchar2,p_user_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
      when 'USER_NO' then
       select max(user_no) into l_rtn from mes_user_b_t where user_id = p_user_id;
      when 'USER_NAME' then
       select max(user_name) into l_rtn from mes_user_b_t where user_id = p_user_id;
      when 'DESCRIPTION' then
       select max(description) into l_rtn from mes_user_b_t where user_id = p_user_id;
      when 'PLANT_CODE' then
       select max(plant_code) into l_rtn from mes_user_b_t where user_id = p_user_id;
      when 'PART_TIME_MARK' then
       select max(part_time_mark) into l_rtn from mes_user_b_t where user_id = p_user_id;
      when 'ROLE_TYPE' then
       select replace(wmsys.wm_concat(func.get_role_inf('ROLE_TYPE',role_num,nvl(apex_application.g_flow_id,64550))),',',':') into l_rtn
          from mes_user_role_t 
         where role_type = 'ROLE_ID' 
           and user_id = p_user_id and (sysdate between active_date and nvl(expire_date,sysdate+1));
    else
       null;
    end case;
    RETURN l_rtn;
    exception when no_data_found then return 'No data found!';
               when others then return 'Unknown error!';
  END get_user_inf;
  
  function get_user_id(p_user_no in varchar2,p_plant_code in varchar2)return number AS
   l_rtn number;
  BEGIN
     select max(user_id) into l_rtn from mes_user_b_t 
     where  user_no = p_user_no
       and plant_code = p_plant_code;
      RETURN l_rtn;
  END get_user_id;

  function get_class_inf(p_type in varchar2,p_class_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'CLASS_CODE' then
      select class_code into l_rtn from mes_class_b_t where class_id = p_class_id;
     when 'CLASS_NAME' then
      select class_name into l_rtn from mes_class_b_t where class_id = p_class_id;
     when 'LEADER_USER_ID' then
      select leader_user_id into l_rtn from mes_class_b_t where class_id = p_class_id;
    else
     null;
    end case;
    RETURN l_rtn;
  END get_class_inf;

  function get_item_inf(p_type in varchar2,p_item_id in number,p_item_no in varchar2)return varchar2 AS
   l_rtn varchar2(200);
   l_machtype varchar2(100);
   l_machinf varchar2(200);
   l_tooltip varchar2(400);
  BEGIN
   if p_item_id is not null then
    case p_type  
     when 'ITEM_NO' then
      select item_no into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'ITEM_DESC1' then
      select item_desc1 into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'ITEM_DESC2' then
      select item_desc2 into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'ITEM_UM' then
      select item_um into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'DUALUM_IND' then
      select dualum_ind into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'SOURCE_ITEM_ID' then
      select source_item_id into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'SOURCE_CODE' then
      select source_code into l_rtn from mes_item_b_t where mes_item_id = p_item_id;
     when 'ITEM_DESC1_HTML' then
      l_tooltip := '簡稱:'||func.get_item_inf('ITEM_DESC2',p_item_id,p_item_no);
      l_rtn := '<span onmouseover="toolTip_enable(event,this,'''||l_tooltip||''')">'||
               func.get_item_inf('ITEM_DESC1',p_item_id,p_item_no)||'</span>';
      else
        null;
    end case;
   end if;
   if p_item_no is not null then
    case p_type
     when 'MES_ITEM_ID' then
      select mes_item_id into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'ITEM_DESC1' then
      select item_desc1 into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'ITEM_DESC2' then
      select item_desc2 into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'ITEM_UM' then
      select item_um into l_rtn from mes_item_b_t where item_no  = p_item_no;
     when 'DUALUM_IND' then
      select dualum_ind into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'SOURCE_ITEM_ID' then
      select source_item_id into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'SOURCE_CODE' then
      select source_code into l_rtn from mes_item_b_t where item_no = p_item_no;
     when 'MACH_INFO' then
      begin
        for x in(select a.mes_mach_id,a.mach_code,a.mach_name,a.mach_group,a.mach_area,a.MES_MACH_TYPE_CODE from mes_mach_b_t a
                   where exists(select 1 from mes_mach_item_ref_t b
                                  where b.item_no = p_item_no
                                    and b.mach_id = a.mes_mach_id) order by a.MES_MACH_TYPE_CODE )loop
         --20161116 Chasty revised:                          
         --l_machtype := func.get_mach_inf('TYPE_NAME',x.mes_mach_id);                    
         --l_machinf := x.mach_code||'【'||x.mach_name||'】'||x.mach_group||'('||x.mach_area||')';
         l_machinf := x.mach_code||'【'||x.mach_name||'】';
         --l_rtn := l_rtn||'、'||'<span onmouseover="toolTip_enable(event,this,'''||l_machinf||''')">'||l_machtype||'</span>';
         l_rtn := l_rtn||'<span onmouseover="toolTip_enable(event,this,'''||l_machinf||''')">'||x.mach_name||'</span>'||'、';        
        end loop;
       exception when no_data_found then
                       l_rtn :='<font color="red">未指定</font>';
                  when others then l_rtn :='<font color="red">資料異常</font>';
      end;
     when 'ITEM_DESC1_HTML' then
      l_tooltip := '簡稱:'||func.get_item_inf('ITEM_DESC2',p_item_id,p_item_no);
      l_rtn := '<span onmouseover="toolTip_enable(event,this,'''||l_tooltip||''')">'||
               func.get_item_inf('ITEM_DESC1',p_item_id,p_item_no)||'</span>';
     else
      null;
    end case;
   end if;
    RETURN l_rtn;
  END get_item_inf;

  function get_whse_inf(p_type in varchar2,p_whse_code in varchar2,p_plant_code in varchar2)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'WHSE_NAME' then
      select whse_name into l_rtn from mes_whse_b_t where whse_code = p_whse_code and plant_code = p_plant_code;
     when 'ERP_WHSE_CODE' then 
      select erp_whse_code into l_rtn from mes_whse_b_t where whse_code = p_whse_code and plant_code = p_plant_code;
     when 'WHSE_AREA' then
      select whse_area into l_rtn from mes_whse_b_t where whse_code = p_whse_code and plant_code = p_plant_code;
    else
     null;
    end case;
    RETURN l_rtn;
  END get_whse_inf;

  function get_mach_inf(p_type in varchar2,p_mach_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'MACH_CODE' then
      select mach_code into l_rtn from mes_mach_b_t where mes_mach_id = p_mach_id;
     when 'MACH_NAME' then
      select mach_name into l_rtn from mes_mach_b_t where mes_mach_id = p_mach_id;
     when 'MACH_GROUP' then
      select mach_group into l_rtn from mes_mach_b_t where mes_mach_id = p_mach_id;
     when 'MACH_AREA' then
      select mach_area into l_rtn from mes_mach_b_t where mes_mach_id = p_mach_id;
     when 'MACH_TYPE' then
      select MES_MACH_TYPE_CODE into l_rtn from mes_mach_b_t where mes_mach_id = p_mach_id;
     when 'TYPE_NAME' then
      select a.lookup_value into l_rtn from mes_lookup_all a,mes_mach_b_t b
        where a.lookup_type = 'MACH_TYPE'
          and a.lookup_code = b.MES_MACH_TYPE_CODE
          and b.mes_mach_id = p_mach_id;
    else
     null;
    end case;
    RETURN l_rtn; 
  END get_mach_inf;

  function get_lot_inf(p_type in varchar2,p_lot_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'MES_ITEM_NO' then
      select item_no into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
     when 'MES_LOT_NO' then
      select lot_no into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
     when 'SOURCE_LOT_NO' then
      select source_lot_no into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
     when 'SOURCE_LOT_DESC' then
      select source_lot_desc into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
     when 'LOT_CREATION_DATE' then
      select lot_creation_date into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
     when 'LOT_EXPIRE_DATE' then
      select lot_expire_date into l_rtn from mes_lot_b_t where mes_lot_id = p_lot_id;
    else
     null;
    end case;
    RETURN l_rtn;
  END get_lot_inf;

  function get_lookup_inf(p_type in varchar2,p_lookup_code in varchar2)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
     select lookup_value into l_rtn from mes_lookup_all 
      where lookup_type = p_type and lookup_code = p_lookup_code;
    RETURN l_rtn;
  END get_lookup_inf;

  function get_batch_inf(p_type in varchar2,p_batch_id in number)return varchar2 AS
   l_rtn varchar2(200);
  BEGIN
    case p_type
     when 'BATCH_NO' then
      select batch_no into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'ITEM_NO' then
      select item_no into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'ITEM_DESC1' then
      select item_desc1 into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'ITEM_UM' then
      select item_um into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'PLAN_QTY' then -- Remember to convert to number
      select plan_qty into l_rtn from mes_batch_t where mes_batch_id  = p_batch_id;
     when 'BATCH_STATUS' then
      select status into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'ACTUAL_START_DATE' then
      select act_start_date into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
     when 'ACTUAL_END_DATE' then
      select act_end_date into l_rtn from mes_batch_t where mes_batch_id = p_batch_id;
    else
     null;
    end case;
    RETURN l_rtn;
  END get_batch_inf;

  function convert_string_to_js(p_source_str in varchar2)return varchar2 AS
  BEGIN
    -- TODO: 必須實行 function FUNC.convert_string_to_js
    RETURN NULL;
  END convert_string_to_js;

  function html_xxx(p_xxx in varchar2)return clob AS
  BEGIN
    -- TODO: 必須實行 function FUNC.html_xxx
    RETURN NULL;
  END html_xxx;
  
  function html_pages(p_app_id in number,p_page_array in varchar2)return clob AS
   l_rtn clob;
   l_cnt number:=0;
  BEGIN
    --
    for i in(select page_id,page_name from  apex_application_pages
         where application_id = p_app_id and instr(':'||p_page_array||':',':'||page_id||':')>0 order by 1) loop            
      if l_cnt < 4 then
         l_rtn := l_rtn||i.page_name||'<font color="blue">|</font>';
         l_cnt := l_cnt+1;
        else
         l_rtn := l_rtn||i.page_name||'</br>';
         l_cnt := 0;         
      end if;
    end loop;
    return l_rtn;
  END html_pages;

  function chk_xxx(p_xxx in varchar2)return number AS
  BEGIN
    -- TODO: 必須實行 function FUNC.chk_xxx
    RETURN NULL;
  END chk_xxx;
  
  function chk_item_mach_unique(p_item_no in varchar2,p_mach_id in number)return boolean AS
   l_cnt number;
  BEGIN
  /*
    select count(a.mach_type) into l_cnt
      from mes_mach_b_t a
     where exists(select 1 from mes_mach_item_ref_t b
                     where b.mach_id = a.mes_mach_id
                       and b.item_no = p_item_no
                       and b.mach_id = p_mach_id)
    select count(b.) into l_cnt 
      from mes_mach_item_ref_t a,
           mes_mach_b_t b
     where a.item_no = p_item_no
       and a.mach_id = p_mach_id;
    */
    if l_cnt > 0 then 
      return false;
    else
      return true;
    end if;
  END chk_item_mach_unique;
  
  function chk_item_mach_exists(p_item_no in varchar2)return boolean AS
   l_cnt number;
  BEGIN
    select count(1) into l_cnt from mes_mach_item_ref_t
     where item_no = p_item_no;
    if l_cnt > 0 then
      return true;
    else
      return false;
    end if;
  END chk_item_mach_exists;

END FUNC;