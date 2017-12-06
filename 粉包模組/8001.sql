--�ݨD�]�tHK
WITH all_plan AS
  (SELECT item_no,
    SUM(Demand_Qty) powder_demand_num,
    plan_start_date
  FROM
    (SELECT ITEM_NO,
      ITEM_DESC1,
      PLAN_START_DATE,
      DEMAND_QTY,
      SOURCE_BATCH_NO,
      MAX(creation_date) creation_date,
      work_version
    FROM mes_demand_qty_t
    WHERE PLAN_START_DATE >= TRUNC(sysdate)
    AND work_version       = 2 --erp�פJ
    GROUP BY ITEM_NO,
      ITEM_DESC1,
      PLAN_START_DATE,
      DEMAND_QTY,
      SOURCE_BATCH_NO,
      work_version
    UNION ALL
    SELECT ITEM_NO,
      ITEM_DESC1,
      PLAN_START_DATE,
      DEMAND_QTY,
      SOURCE_BATCH_NO,
      creation_date,
      work_version
    FROM mes_demand_qty_t
    WHERE PLAN_START_DATE >= TRUNC(sysdate)
    and work_version = 1  --mes��J
--    AND source_batch_no LIKE 'H%'
    )
  GROUP BY item_no,
    plan_start_date
  ),
  erp_onhand AS
  ( SELECT DISTINCT item_no ,
    SUM(onhand_qty) onhand_qty
  FROM MES_WIP_ONHAND_QTY_WK_T
  WHERE MES_WIP_ONHAND_QTY_WK_T.creation_date =
    (SELECT MAX(creation_date) FROM MES_WIP_ONHAND_QTY_WK_T
    )
  GROUP BY item_no
  ),
  erp_powder_plan AS
  (SELECT SUM(plan_qty) qty,
    Wip_Batch_Status_V.Item_No,
    WIP_BATCH_STATUS_V.plan_start_date,
    Wip_Batch_Status_V.Item_Desc1
  FROM WIP_BATCH_STATUS_V
  JOIN Mes_Oprn_Item_Ref_T
  ON WIP_BATCH_STATUS_V.item_no           = Mes_Oprn_Item_Ref_T.item_no
  WHERE mes_oprn_item_ref_t.oprn_code     = 50
  AND Wip_Batch_Status_V.Plan_Start_Date >= TRUNC(sysdate)
  AND WIP_BATCH_STATUS_V.batch_status    <>'Cancel'
  GROUP BY Wip_Batch_Status_V.Item_No,
    WIP_BATCH_STATUS_V.plan_start_date,
    Wip_Batch_Status_V.Item_Desc1
  ),
  mes_powder_plan AS
  (SELECT Mes_Supy_Plan_T.PLAN_START_DATE,
    Mes_Supy_Plan_T.item_no,
    SUM(PLAN_DEMAND_QTY) mes_plan_qty,
    MES_ITEM_B_T.ITEM_DESC3 ITEM_DESC3
  FROM Mes_Supy_Plan_T
  JOIN Mes_Oprn_Item_Ref_T
  ON Mes_Supy_Plan_T.item_no           = Mes_Oprn_Item_Ref_T.item_no
  JOIN MES_ITEM_B_T
  ON Mes_Supy_Plan_T.ITEM_NO = MES_ITEM_B_T.ITEM_NO
  WHERE Mes_Oprn_Item_Ref_T.Oprn_Code  =50
  AND Mes_Supy_Plan_T.PLAN_START_DATE >= TRUNC(sysdate)
  and PLAN_DEMAND_QTY >0
  GROUP BY Mes_Supy_Plan_T.item_no,
    Mes_Supy_Plan_T.PLAN_START_DATE,MES_ITEM_B_T.ITEM_DESC3
  )
SELECT COALESCE(mes_item_b_t.item_no,all_plan.item_no,Erp_Powder_Plan.item_no,Mes_Powder_Plan.Item_No) Item_No,
  COALESCE(Mes_Item_B_T.Item_Desc3,erp_powder_plan.Item_Desc1,mes_powder_plan.ITEM_DESC3) Item_Desc3,
  (COALESCE(all_plan.powder_demand_num,0)) powder_demand_num,                                                               -- "�i�}�����]�ݨD�ƶq" ,
  COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE) plan_start_date,       --���]���ݨD��,
  COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE) powder_demand_date,    --���]���ݨD��(����)
  (COALESCE(onhand_qty,0)) onhand_qty,                                                                                      --��w�s�q
  (COALESCE(erp_powder_plan.qty,0)) ERP_qty,                                                                                --ERP�w�}�����q
  (COALESCE(COALESCE(onhand_qty,0) - COALESCE(all_plan.powder_demand_num,0) + COALESCE(erp_powder_plan.qty,0),0)) lack_num, --ERP�w���ʮƶq
  (COALESCE(mes_powder_plan.mes_plan_qty,0)) mes_plan_qty,                                                                  --mes�w�}�����q
  APEX_ITEM.TEXT(5,'0',10,10) user_input,                                                                                   --��J�����q
  APEX_ITEM.HIDDEN(6,COALESCE(Mes_Item_B_T.item_no,erp_powder_plan.item_no,mes_powder_plan.item_no),10,10) item_no2,
  APEX_ITEM.HIDDEN(7,COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE)) plan_start_date2,
  COALESCE(COALESCE(onhand_qty,0) - COALESCE(all_plan.powder_demand_num,0) + COALESCE(erp_powder_plan.qty,0)+ COALESCE(mes_powder_plan.mes_plan_qty,0),0) mes_lack ,                                                                   --mes�w���ʮƶq
  ROW_NUMBER() OVER(PARTITION BY COALESCE(Mes_Item_B_T.item_no,erp_powder_plan.item_no,mes_powder_plan.item_no) ORDER BY COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE) ASC) sort ,--�Ƨǥ�
  case when ROW_NUMBER() OVER(PARTITION BY COALESCE(Mes_Item_B_T.item_no,erp_powder_plan.item_no,mes_powder_plan.item_no) ORDER BY COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE) ASC) = 1 then 
  '<i class="fa fa-plus" style="font-size:25px;color:black"></i>' else '' end link_button
FROM mes_item_b_t
left JOIN erp_onhand
ON erp_onhand.item_no = mes_item_b_t.item_no
left JOIN Mes_Oprn_Item_Ref_T
ON mes_item_b_t.item_no           = Mes_Oprn_Item_Ref_T.item_no
AND Mes_Oprn_Item_Ref_T.oprn_code = 50
LEFT JOIN all_plan
ON mes_item_b_t.item_no = all_plan.item_no
FULL JOIN erp_powder_plan
ON erp_powder_plan.item_no          = mes_item_b_t.item_no
AND Erp_Powder_Plan.Plan_Start_Date = All_Plan.Plan_Start_Date
FULL JOIN mes_powder_plan
ON mes_powder_plan.item_no          = mes_item_b_t.item_no
AND Mes_Powder_Plan.Plan_Start_Date = COALESCE(all_plan.plan_start_date,Erp_Powder_Plan.Plan_Start_Date)
where COALESCE(all_plan.plan_start_date,erp_powder_plan.plan_start_date,mes_powder_plan.PLAN_START_DATE) is not null --�o�����w�s�S�ݨD�ΨS�w�s�S�ݨD
ORDER BY COALESCE(Mes_Item_B_T.item_no,erp_powder_plan.item_no,mes_powder_plan.item_no) 