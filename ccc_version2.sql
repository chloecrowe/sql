declare     @date_start date = '2023-02-01',
            @date_end date = '2023-03-01'

;with sr as (

select        
            sr.service_request_code,
            --sr.sr_type,
            --srt.service_request_type,
            --si.description,
            --sr.location_street, 
            --sr.location_no,
            ss.sr_status_date,
            --ss.sr_status_type,
            --sst.sr_status_description,
            --sp.predominant_flag,
			spt.sr_perorg_type,
            --spa.perorg_address_type,
            spa.full_address,

			row_number() over (partition by sr.service_request_code, sp.perorg_code order by ss.sr_status_date) rn_person,

            RANK() OVER (
					PARTITION BY sr.service_request_code
					ORDER BY 
					  CASE spt.sr_perorg_type_id
						WHEN 1 THEN 1
						WHEN 3 THEN 2
						WHEN 5000009 THEN 3
						ELSE 4
					  END ASC
				  ) AS rank_num

from        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.service_request sr

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.service_request_type srt on srt.sr_type = sr.sr_type

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_item si on si.service_request_code = sr.service_request_code
                                          					 and si.sr_item_code = 1			--Only first item

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_status ss on ss.sr_item = si.sr_item
                                            				   and ss.sr_status_date between @date_start and @date_end

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_status_type sst on ss.sr_status_type = sst.sr_status_type

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_perorg sp on sp.service_request_code = sr.service_request_code

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_perorg_address_details_vw spa on spa.sr_perorg = sp.sr_perorg
                                                                				   and spa.teamwork_address_type_id = 8 --Email
																			   and spa.valid_to is null

join        [EC2AMAZ-N6EIMLS].ecbu_teamwork_sr.dbo.sr_perorg_type spt on spt.sr_perorg_type_id = sp.sr_perorg_type_id
                                                  					 and spt.sr_perorg_type_id in (1, 11, 3, 5000009) --  11 Owner, 1 Agent, 3 Architect, 5000009 Engineer

join        [EC2AMAZ-N6EIMLS].customer.dbo.customer cu on cu.customer_number = sp.perorg_code

where       1=1

and         ( 		(    sr.sr_type in (7) and ss.sr_status_type in (3066,3071)    )        -- aBLDG CONSENT - 3066 Consent Issued, 3071 CCC Issued, 3073 Completed
            or		(    sr.sr_type in (85) and ss.sr_status_type in (3121)        )        -- RC - a Res.Con - Issued
            )
)

select		s.*

from		sr s

inner join (
    select service_request_code, min(rank_num) as min_rank
    from sr
    group by service_request_code) groupedsr

on s.service_request_code = groupedsr.service_request_code
and s.rank_num = groupedsr.min_rank

where		rn_person = 1 
