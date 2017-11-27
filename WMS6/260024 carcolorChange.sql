DECLARE
l_sql VARCHAR(10000);
dateformat VARCHAR(10);
BEGIN
dateformat := q'['yyyymmdd']';

l_sql:='
WITH ware_num AS
  (SELECT item_no,
    ver_id ,
    order_no,
    car_group,
    cust_id ,
    Ware_Area_Id,
    SUM(end_qty) qty_num,
    id
  FROM
    (SELECT Wms006.Item_No item_no,
      Wms006.Ver_Id ver_id,
      wms005.order_no order_no,
      wms245.sale_date sale_date,
      wms005.cust_id cust_id,
      mfa041.ship_cust_name ship_cust_name,
      mfa001.item_short_name item_short_name,
      wms005.id ,
      wms245.car_group car_group,
      wms007.manu_date¡@manu_date,
      Wms221.Ware_Area_Id ware_area_id,
      SUM(Wms007.End_Qty) end_qty
    FROM wms006
    JOIN wms005
    ON wms005.id = Wms006.Parent_Id
    JOIN MFA047
    ON WMS005.CUST_ID= MFA047.CUST_ID
    JOIN wms245
    ON Wms006.Car_Group = Wms245.Car_Group
    JOIN mfa041
    ON mfa041.cust_id = wms005.cust_id
    JOIN mfa001
    ON mfa001.item_no = wms006.item_no
    JOIN MFA037
    ON WMS006.ITEM_NO = MFA037.ITEM_NO
    AND mfa037.dc_id  =:p101_dc_id
    JOIN wms025
    ON wms025.keep_time_type      =mfa037.keep_time_type
    AND wms025.cust_classify_type =mfa047.cust_classify_type
    left JOIN wms069
    ON wms069.GROUP_WARE_ID   = :P101_ware_id
    AND wms069.FORCE_GROUP_ID = wms005.cust_id
    AND wms069.BAR_CODE_L     = wms006.item_no
    JOIN wms007
    ON wms007.end_qty         >0
    AND wms007.locn_id        >9
    AND wms007.locn_id       <> 4900
    AND wms007.item_no        = wms006.item_no
    and wms007.ver_id = wms006.ver_id
    AND Wms007.Item_Stat_Mark = 1
    JOIN wms021
    ON wms007.locn_id  = wms021.locn_id
    AND wms021.ware_id = :P101_ware_id
    JOIN wms221
    ON Wms221.Ware_Area_Id                                    = wms021.ware_area_id
    WHERE wms006.car_group                                   IS NOT NULL
    AND wms006.ORDER_QTY_I +ORDER_QTY_F+GIFT_QTY_I+GIFT_QTY_F >0
    AND Wms245.Sale_Date                                     >= TRUNC(sysdate)
    AND Wms005.Omstat                                        IS NULL
    GROUP BY Wms006.Item_No,
      Wms006.Ver_Id,
      wms005.order_no,
      wms245.sale_date,
      wms005.cust_id,
      mfa041.ship_cust_name,
      mfa001.item_short_name,
      wms005.id,
      wms245.car_group,
      wms005.due_date-wms025.accept_days,
      WMS006.ACCEPT_DATE,
      Wms069.Manu_Date ,
      Wms007.Manu_Date,
      Wms221.Ware_Area_Id
    HAVING (wms007.manu_date >=
      CASE
        WHEN accept_date IS NULL
        THEN greatest(NVL(wms005.due_date-wms025.accept_days + 1,to_date(20170101,'||dateformat||')),NVL(Wms069.Manu_Date,to_date(20170101,'||dateformat||')),NVL(Wms006.accept_Date,to_date(20170101,'||dateformat||')))
        ELSE wms007.manu_date
      END )
    )
  GROUP BY item_no,
    ver_id,
    order_no,
    cust_id ,
    car_group ,
    Ware_Area_Id,
    id
  ),
  ava_ware_num_4 AS
  ( SELECT DISTINCT Mfa001.Item_Short_Name item_name,
    wms007.item_no,
    Wms007.Ver_Id,
    SUM(end_qty) over(partition BY wms007.item_no,wms007.ver_Id,wms021.ware_area_id) qty_num,                  
    SUM(end_qty) over(partition BY wms007.item_no,wms007.ver_Id,wms007.manu_date,wms021.ware_area_id) qty_num2,
    Wms007.Manu_Date,
    Mfa001.Check_Days,
    Wms221.Ware_Area_Id
  FROM wms007
  LEFT JOIN mfa001
  ON wms007.item_no = mfa001.item_no
  JOIN mfa037
  ON mfa037.item_no = mfa001.item_no
  JOIN wms021
  ON wms021.locn_Id  = wms007.locn_id
  AND Wms021.Ware_Id = :P101_ware_id
  JOIN wms221
  ON wms221.ware_area_id    = Wms021.Ware_Area_Id
  WHERE Wms007.End_Qty      >0
  AND Wms007.locn_id NOT   IN (8,9,4900)
  AND Wms007.item_stat_mark =4
  ),
  order_num AS
  (SELECT DISTINCT Wms006.Item_No,
    Wms006.Ver_Id,
    NVL(SUM(Wms006.Order_Qty_I+Wms006.Gift_Qty_I) over(partition BY Wms006.Item_No, Wms006.Ver_Id,Wms245.Ware_Area_Id),0) order_num,
    wms005.order_no,
    NVL(SUM(Wms006.Order_Qty_I+Wms006.Gift_Qty_I) over(partition BY Wms006.Item_No, Wms006.Ver_Id,wms005.order_no,Wms245.Ware_Area_Id),0) order_num2 ,
    wms245.sale_date,
    wms005.cust_id,
    mfa041.ship_cust_name,
    mfa001.item_short_name,
    wms005.id,
    wms245.car_group,
    wms245.ware_area_id,
    wms006.accept_date,
    NVL(wms005.due_date-wms025.accept_days + 1,to_date(20170101,'||dateformat||')) original_accept_date,
    NVL(Wms069.Manu_Date,to_date(20170101,'||dateformat||')) last_time_manu_date,
    CASE
      WHEN accept_date IS NULL
      THEN greatest(NVL(wms005.due_date-wms025.accept_days + 1,to_date(20170101,'||dateformat||')),NVL(Wms069.Manu_Date,to_date(20170101,'||dateformat||')))
      ELSE accept_date
    END final_accept_date
  FROM wms006
  JOIN wms005
  ON wms005.id = Wms006.Parent_Id
  JOIN MFA047
  ON WMS005.CUST_ID= MFA047.CUST_ID
  JOIN wms245
  ON Wms006.Car_Group = Wms245.Car_Group
  JOIN mfa041
  ON mfa041.cust_id = wms005.cust_id
  JOIN mfa001
  ON mfa001.item_no = wms006.item_no
  JOIN MFA037
  ON WMS006.ITEM_NO = MFA037.ITEM_NO
  AND mfa037.dc_id  =:p101_dc_id
  JOIN wms025
  ON wms025.keep_time_type      =mfa037.keep_time_type
  AND wms025.cust_classify_type =mfa047.cust_classify_type
  left JOIN wms069
  ON wms069.GROUP_WARE_ID                                   = :P101_ware_id
  AND wms069.FORCE_GROUP_ID                                 = wms005.cust_id
  AND wms069.BAR_CODE_L                                     = wms006.item_no
  WHERE wms006.car_group                                   IS NOT NULL
  AND wms006.ORDER_QTY_I +ORDER_QTY_F+GIFT_QTY_I+GIFT_QTY_F >0
  AND Wms245.Sale_Date                                     >= TRUNC(sysdate)
  AND Wms005.Omstat                                        IS NULL
  ),
  out_num AS
  (SELECT DISTINCT wms006.Item_No item_no,
    wms006.ver_id,
    wms005.order_no,
    SUM(wms092.out_num) over(partition BY wms006.Item_No, wms006.ver_id) Out_Num,
    NVL(SUM(wms092.out_num) over(partition BY wms006.Item_No, wms006.ver_id,wms005.order_no),0) Out_Num2 ,
    Wms245.Ware_Area_Id
  FROM wms005
  JOIN wms006
  ON wms005.id = wms006.parent_id
  LEFT JOIN wms092
  ON wms006.id =wms092.parent_id
  JOIN wms245
  ON Wms245.Car_Group     = Wms006.Car_Group
  WHERE Wms245.Sale_Date >= TRUNC(sysdate)
  AND Wms092.Scrap_Code  IS NULL
  )
SELECT ¡@order_num.item_no¡@item_no,
  order_num.order_num order_num,
  order_num.order_no order_no,
  out_num.out_num2 order_no2
FROM order_num
LEFT JOIN ware_num
ON order_num.item_no       = ware_num.item_no
AND order_num.ver_id       = ware_num.ver_id
AND order_num.ware_area_id = ware_num.ware_area_id
AND order_num.id           = ware_num.id
LEFT JOIN out_num
ON order_num.item_no       =out_num.item_no
AND order_num.ver_id       = Out_Num.Ver_Id
AND order_num.order_no     = out_num.order_no
AND order_num.ware_area_id = Out_Num.Ware_Area_Id
LEFT JOIN ava_ware_num_4
ON order_num.item_no       =ava_ware_num_4.item_no
AND order_num.ver_id       = ava_ware_num_4.Ver_Id
AND order_num.ware_area_id = ava_ware_num_4.ware_area_id
JOIN wms010
ON wms010.ver_id = order_num.ver_id
WHERE NVL(ware_num.qty_num,0) + (
  CASE
    WHEN sale_date - manu_date >= ava_ware_num_4.check_Days
    THEN NVL(ava_ware_num_4.qty_num,0)
    ELSE 0
  END) - NVL((order_num.order_num -NVL(out_num.Out_Num,0)),0) <0
and order_num.car_group = :P260024_CAR_GROUP
';


apex_util.json_from_sql(l_sql);


END;