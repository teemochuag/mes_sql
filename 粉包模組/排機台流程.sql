--20171122
for select(每日、班別，機台優先順序(機台資源))
    for select(每日、產品、產品優先次序(組合機台的粉包先排))
        select 產品是不是組合機台
        select 機台是否可以生產該產品
        select 機台剩餘可用時間
        select 產品剩餘未排分鐘數
        if  機台是否還有剩餘時間可以安排
            if  產品還有剩餘時間要排 (l_unprod_min <= 0)
                continue
            else:
                if  機台是否可以生產該產品(mach_ava_prod           > 0)
                    if 當非組合機台 或是 非組合機台產品 (R_AVA_MACH.groupable IS NULL OR G_main_ava_item = 0)
                        if  製作耗時 < 機台可用 (l_unprod_min < ava_minute THEN)
                            UPDATE Mes_Mach_Daily_T 
                                Work_Minute                          = ava_minute - l_unprod_min --(機台可用 = 機台可用 - 製造耗用)
                            INSERT  INTO mes_plan_mach_wk_t 
                                use_work_minute = l_unprod_min --機台耗用時間 = 製作耗時
                                PLAN_QTY        = l_unprod_qty --產品生產數量
                        else:  製作耗時 > 機台可用 
                            select 用機台可用去計算製造數量 into l_unprod_qty
                            UPDATE Mes_Mach_Daily_T
                                 Work_Minute                          = 0 --可用時間全吃
                            INSERT  INTO mes_plan_mach_wk_t 
                                use_work_minute = ava_minute    --機台可用
                                plan_qty        = l_unprod_qty  --產品生產數量
                        end if
                    else --組合機台
                        
                        for select mes_mach_group_b_t 找出同組的機器，最小可用
                            select 用最小可用去計算生產數量 into l_unprod_qty
                            if g_mach.ava_mach_min = 0 已經有一台沒有可用時間了，都不能排
                                break;
                            else 可以排
                                if l_unprod_min /2                 > g_mach.min_work_minute THEN --(製作耗時)/2 > 最小可用
                                    UPDATE Mes_Mach_Daily_T
                                        Work_Minute = g_mach.ava_mach_min
                                    INSERT INTO mes_plan_mach_wk_t
                                        use_work_minute     =   g_mach.min_work_minute --最小可用
                                        plan_qty            =   ceil(l_unprod_qty)  --
                                else    --(製作耗時)/2 < 最小可用
                                    select 用還未製造的分鐘數去算 還未製造的數量
                                    UPDATE  mes_mach_daily_t
                                        work_minute                          = ceil(g_mach.min_work_minute - (l_unprod_min/2)) --最小可用 - 分鐘數/2
                                    INSERT INTO 
                                        use_work_minute =   ceil(l_unprod_min/2)
                                        plan_qty    =   ceil(l_unprod_qty/2) )
                                end if;
                        end loop; 
                    end if    
                else:
                    end if;
            end if;
        else 非組合機台
        end if;
end loop;
