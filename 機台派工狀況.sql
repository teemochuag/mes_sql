--機台派工狀況
--版本測試66777
WITH mach_default_min AS
  (SELECT Mes_Mach_B_T.Mach_Code Mach_Code,
    Mes_Mach_B_T.Mach_Name Mach_Name,
    Area_Work_Type_T.Class_Code Class_Code,
    Area_Work_Type_T.Minute default_min,
    Mes_Class_B_T.class_name
  FROM Area_Work_Type_T
  JOIN Mes_Mach_B_T
  ON Area_Work_Type_T.Mach_Area = Mes_Mach_B_T.Mach_Area
  JOIN Mes_Class_B_T
  ON Area_Work_Type_T.class_code = Mes_Class_B_T.class_code
  WHERE oprn_code                = 50
  ) ,
  supy_plan AS
  (SELECT Mes_Mach_Daily_T.Work_Minute ava_min,
    mach_code mach_code,
    Mes_Mach_Daily_T.Plan_Date Plan_Date,
    Mes_Mach_Daily_T.Class_Code　Class_Code
  FROM Mes_Mach_Daily_T
  )
SELECT mach_default_min.mach_code mach_code,
  Mach_Default_Min.Mach_Name,
  Mach_Default_Min.Mach_Name,
  mach_default_min.Class_Code Class_Code,
  mach_default_min.default_min default_min,
  supy_plan.ava_min,
  Supy_Plan.Plan_Date,
  mach_default_min.class_name class_name,
  case　when default_min           = 0 THEN '機台不可用' WHEN mach_default_min.default_min                 - supy_plan.ava_min = 0 THEN '未排生產' WHEN supy_plan.ava_min = 0
AND mach_default_min.default_min <>0 THEN '滿載' ELSE '0'||TO_CHAR(ROUND((mach_default_min.default_min - supy_plan.ava_min) / mach_default_min.default_min,2))
END used_percent --(預設-可用)= 已用， 已用/預設 = 已用比率
FROM mach_default_min
JOIN supy_plan
ON Mach_Default_Min.Mach_Code   = supy_plan.mach_code
AND mach_default_min.Class_Code = supy_plan.Class_Code
WHERE Supy_Plan.Plan_Date      >= TRUNC(sysdate)+2