DECLARE
  ava_minute      NUMBER;
  l_item_no       VARCHAR2(32);
  l_mach_code     VARCHAR2(10);
  MACH_DAILY_ID   NUMBER;
  l_unprod_min    NUMBER;
  mach_ava_prod   NUMBER;
  item_prod_min   NUMBER;
  L_UNPROD_QTY    NUMBER;
  G_mach_ava_prod NUMBER;
  G_mach_code     VARCHAR2(10);
  G_min_ava_prod  NUMBER;
  G_main_ava_item NUMBER;
  CURSOR AVA_MACH
  IS --���x�u������
    SELECT Mes_Mach_Daily_T.mach_code,
      mach_pri.mach_priority,
      Mes_Mach_Daily_T.Plan_Date,
      Mes_Mach_Daily_T.class_code,
      groupable.mach_code groupable
    FROM Mes_Mach_Daily_T,
      (SELECT COUNT(mach_code) mach_priority,
        mach_code
      FROM Mes_Mach_Item_Attr_T
      GROUP BY mach_code
      )mach_pri,
    (SELECT DISTINCT mach_code FROM Mes_Mach_Group_B_T
    ) groupable
  WHERE Mes_Mach_Daily_T.Mach_Code = Mach_Pri.Mach_Code(+)
    --AND Mes_Mach_Daily_T.Work_Minute <>0
  AND Mes_Mach_Daily_T.Plan_Date >= TRUNC(sysdate)+2
  AND Mes_Mach_Daily_T.mach_code  = groupable.mach_code(+)
  ORDER BY plan_date ASC,
    class_code ASC,
    mach_priority ASC;
BEGIN
  FOR R_AVA_MACH IN AVA_MACH
  LOOP
    FOR PLAN_ITEM IN
    (SELECT Mes_Supy_Plan_T.item_no item_no,
      SUM(Plan_Product_Qty) Plan_Product_Qty,
      GROUP_ENABLE
    FROM Mes_Supy_Plan_T
    JOIN mes_item_b_t
    ON Mes_Supy_Plan_T.item_no      = mes_item_b_t.item_no
    WHERE Mes_Supy_Plan_T.work_date = R_AVA_MACH.Plan_Date
    GROUP BY Mes_Supy_Plan_T.item_no,
      GROUP_ENABLE
    ORDER BY GROUP_ENABLE DESC
    )
    LOOP
    --���~�O���O�D�զX���x���~ 1�զX 0�D�զX
      SELECT COUNT(*) INTO G_main_ava_item 
      FROM mes_mach_group_b_t WHERE mes_mach_group_b_t.item_no = PLAN_ITEM.item_no ;
      SELECT COUNT(*) --���x�i�H�Ͳ��Ӳ��~
      INTO mach_ava_prod
      FROM Mes_Mach_Item_Attr_T�@
      WHERE item_no = PLAN_ITEM.item_no
      AND Mach_Code = R_AVA_MACH.mach_code;
      SELECT MACH_CODE,--���x�Ѿl�i��
        Work_Minute,
        Mes_Mach_Daily_T.Mes_Mach_Daily_ID
      INTO l_mach_code,
        ava_minute,
        MACH_DAILY_ID
      FROM Mes_Mach_Daily_T
      WHERE Mes_Mach_Daily_T.MACH_CODE = R_AVA_MACH.MACH_CODE
      AND Plan_Date                    = R_AVA_MACH.Plan_Date
      AND class_code                   = R_AVA_MACH.class_code;
      BEGIN --���o���~�Ѿl�s�y����
      WITH plan_item_qty AS
        (SELECT Mes_Supy_Plan_T.item_no,
          SUM(plan_product_qty) plan_product_qty,
          Mes_Supy_Plan_T.Work_Date
        FROM Mes_Supy_Plan_T
        WHERE Mes_Supy_Plan_T.Work_Date = R_AVA_MACH.Plan_Date
        GROUP BY Mes_Supy_Plan_T.item_no,
          plan_product_qty,
          Mes_Supy_Plan_T.Work_Date
        ),
        proded_qty AS
        (SELECT item_no,
          PLAN_START_DATE,
          SUM(PLAN_QTY) PLAN_QTY --�w�ƥͲ��ƶq
        FROM mes_plan_mach_wk_t
        WHERE PLAN_START_DATE = R_AVA_MACH.Plan_Date
        GROUP BY item_no,
          PLAN_START_DATE
        )
      SELECT
        --plan_item_qty.item_no,
        --Mes_Mach_Item_Attr_T.mach_code,
        plan_item_qty.plan_product_qty       - NVL(proded_qty.PLAN_QTY,0) unprod_qty,             --�Ѿl�n�s�y�ƶq
        ceil((plan_item_qty.plan_product_qty - NVL(proded_qty.PLAN_QTY,0))/mach_speed) unprod_min --�Ѿl�n�s�y�ɶ�
      INTO l_unprod_qty,
        l_unprod_min
      FROM plan_item_qty
      LEFT JOIN proded_qty
      ON plan_item_qty.item_no    = proded_qty.item_no
      AND plan_item_qty.work_date = proded_qty.PLAN_START_DATE
      JOIN Mes_Mach_Item_Attr_T
      ON plan_item_qty.item_no           = Mes_Mach_Item_Attr_T.item_no
      WHERE plan_item_qty.item_no        = PLAN_ITEM.item_no
      AND R_AVA_MACH.Plan_Date           = plan_item_qty.work_date
      AND Mes_Mach_Item_Attr_T.mach_code = R_AVA_MACH.mach_code;
    EXCEPTION
    WHEN no_data_found THEN
      l_unprod_min  :=0 ; --���~�٥��Ͳ�������
      l_unprod_qty  :=0;  --���~�Ͳ��ƶq
    END;
--    dbms_output.put_line ('�Ѿl���s�y '||ava_minute||'-'||l_unprod_min||'\'||PLAN_ITEM.item_no||'\'||mach_ava_prod||'\'||R_AVA_MACH.mach_code||'\'||R_AVA_MACH.class_code||'\'||R_AVA_MACH.groupable);
    IF ava_minute      > 0 THEN --���x�٦��Ѿl�ɶ��i�w��
      IF l_unprod_min <= 0 THEN --���~�٦��Ѿl�ɶ��n��
        CONTINUE;
      ELSE
        IF mach_ava_prod           > 0 THEN                           --�Ӿ��x�i�H�Ͳ��Ӳ��~
          IF R_AVA_MACH.groupable IS NULL OR G_main_ava_item = 0 THEN --�D�զX���x
--            dbms_output.put_line ('�ƾ��x�}�l '||PLAN_ITEM.item_no||'\'||l_unprod_qty);
            IF l_unprod_min < ava_minute THEN --�s�@�Ӯ� < ���x�i��
              UPDATE Mes_Mach_Daily_T
              SET Work_Minute                          = ava_minute - l_unprod_min --(���x�i�� = ���x�i�� - �s�y�ӥ�)
              WHERE Mes_Mach_Daily_T.Mes_Mach_Daily_ID = MACH_DAILY_ID;
--              dbms_output.put_line ('�s�@�Ӯ� < ���x�i�� '||ava_minute||'\'||l_unprod_qty);
              INSERT
              INTO mes_plan_mach_wk_t
                (
                  work_date,
                  PLAN_START_DATE,
                  MACH_CODE,
                  GROUP_ENABLE,
                  ITEM_NO,
                  use_work_minute,
                  class_code,
                  PLAN_QTY
                )
                VALUES
                (
                  TO_CHAR(sysdate,'yyyymmdd'),
                  R_AVA_MACH.Plan_Date,
                  R_AVA_MACH.MACH_CODE,
                  'N',
                  PLAN_ITEM.item_no,
                  l_unprod_min,
                  R_AVA_MACH.class_code,
                  l_unprod_qty
                );
            ELSE --�s�@�Ӯ� > ���x�i��
              UPDATE Mes_Mach_Daily_T
              SET Work_Minute                          = 0 --(���x�i�� = ���x�i�� - �s�y�ӥ�)
              WHERE Mes_Mach_Daily_T.Mes_Mach_Daily_ID = MACH_DAILY_ID;
              SELECT Mach_Speed*ava_minute into�@l_unprod_qty
              FROM Mes_Mach_Item_Attr_T
              WHERE Mes_Mach_Item_Attr_T.item_no = PLAN_ITEM.item_no
              AND Mes_Mach_Item_Attr_T.mach_code = R_AVA_MACH.MACH_CODE;
--              dbms_output.put_line ('�s�@�Ӯ� > ���x�i�� '||ava_minute||'\'||l_unprod_qty);
              INSERT
              INTO mes_plan_mach_wk_t
                (
                  work_date,
                  PLAN_START_DATE,
                  MACH_CODE,
                  GROUP_ENABLE,
                  ITEM_NO,
                  use_work_minute,
                  class_code,
                  plan_qty
                )
                VALUES
                (
                  TO_CHAR(sysdate,'yyyymmdd'),
                  R_AVA_MACH.Plan_Date,
                  R_AVA_MACH.MACH_CODE,
                  'N',
                  PLAN_ITEM.item_no,
                  ava_minute,
                  R_AVA_MACH.class_code,
                  l_unprod_qty
                );
            END IF;
          ELSE            --�զX���x
            FOR g_mach IN --�����i�ΡA�P�ժ�����
            (SELECT mach_code mach_code,
                work_minute work_minute,
                MIN(work_minute) min_work_minute ,
                Mes_mach_daily_ID mes_mach_daily_ID,
                work_minute - MIN(work_minute) ava_mach_min,
                Class_Code
              FROM mes_mach_daily_t
              WHERE mes_mach_daily_t.plan_date = R_AVA_MACH.Plan_Date
              AND Class_Code                   = R_AVA_MACH.class_code
              AND mach_code                   IN
                (SELECT mach_code
                FROM Mes_Mach_Group_B_T
                WHERE mes_mach_group_code =
                  (SELECT Mes_Mach_Group_Code
                  FROM Mes_Mach_Group_B_T
                  WHERE mach_code = R_AVA_MACH.MACH_CODE
                  AND item_no     = PLAN_ITEM.item_no
                  )
                )
              AND work_minute <> 0
              GROUP BY mach_code,
                work_minute,
                Mes_mach_daily_ID,Class_Code
            )
            LOOP
              SELECT ceil(Mach_Speed*g_mach.min_work_minute) into�@l_unprod_qty
              FROM Mes_Mach_Item_Attr_T
              WHERE Mes_Mach_Item_Attr_T.item_no = PLAN_ITEM.item_no
              AND Mes_Mach_Item_Attr_T.mach_code = g_mach.mach_code;
--              dbms_output.put_line ('XXZ '||g_mach.min_work_minute||'\'||g_mach.mach_code||'\'||PLAN_ITEM.item_no);
              IF g_mach.min_work_minute = 0  THEN --�w�g���@�x�S���i�ήɶ��F�A�������
              EXIT;
              ELSE
              IF l_unprod_min /2                 > g_mach.min_work_minute THEN --(�s�@�Ӯ�)/2 > �̤p�i��
                UPDATE mes_mach_daily_t
                SET work_minute = g_mach.min_work_minute
                WHERE Mes_Mach_Daily_T.Mes_Mach_Daily_ID = g_mach.mes_mach_daily_ID;
--                dbms_output.put_line ('(�s�@�Ӯ�)/2 > �̤p�i�� '||l_unprod_min/2||'\'||g_mach.min_work_minute||'\'||l_unprod_qty||'\'||g_mach.mach_code);
                INSERT
                INTO mes_plan_mach_wk_t
                  (
                    work_date,
                    PLAN_START_DATE,
                    MACH_CODE,
                    GROUP_ENABLE,
                    ITEM_NO,
                    use_work_minute,
                    class_code,
                    plan_qty
                  )
                  VALUES
                  (
                    TO_CHAR(sysdate,'yyyymmdd'),
                    R_AVA_MACH.Plan_Date,
                    g_mach.mach_code,
                    'Y',
                    PLAN_ITEM.item_no,
                    g_mach.min_work_minute,
                    R_AVA_MACH.class_code,
                    l_unprod_qty
                  );
              ELSE --(�s�@�Ӯ�)/2 < �̤p�i��
--                dbms_output.put_line ('(�s�@�Ӯ�)/2 < �̤p�i��'||l_unprod_min/2||'\'||g_mach.min_work_minute||'\'||l_unprod_qty||'\'||g_mach.mach_code);
                SELECT Mach_Speed                                    *l_unprod_min into�@l_unprod_qty
                FROM Mes_Mach_Item_Attr_T
                WHERE Mes_Mach_Item_Attr_T.item_no = PLAN_ITEM.item_no
                AND Mes_Mach_Item_Attr_T.mach_code = g_mach.mach_code;
                UPDATE mes_mach_daily_t
                SET work_minute                          = (g_mach.min_work_minute - ceil(l_unprod_min/2))
                WHERE Mes_Mach_Daily_T.Mes_Mach_Daily_ID = g_mach.mes_mach_daily_ID;
                INSERT
                INTO mes_plan_mach_wk_t
                  (
                    work_date,
                    PLAN_START_DATE,
                    MACH_CODE,
                    GROUP_ENABLE,
                    ITEM_NO,
                    use_work_minute,
                    class_code,
                    plan_qty
                  )
                  VALUES
                  (
                    TO_CHAR(sysdate,'yyyymmdd'),
                    R_AVA_MACH.Plan_Date,
                    g_mach.mach_code,
                    'Y',
                    PLAN_ITEM.item_no,
                    ceil(l_unprod_min/2),
                    R_AVA_MACH.class_code,
                    ceil(l_unprod_qty/2) );
                --                EXIT;
              END IF;
              END IF;      
            END LOOP;
          END IF;--�զX���x
        ELSE     --�Ӿ��x���i�H�Ͳ��Ӳ��~
          CONTINUE;
        END IF;
      END IF;
    ELSE
      EXIT;
    END IF;
  END LOOP;
END LOOP;
END;