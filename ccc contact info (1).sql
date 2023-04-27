declare		@date_start date = '2023-02-01',
			@date_end date = '2023-02-03'


;with sr as (

select		
			sr.service_request_code,

			--sr.sr_type,
			srt.service_request_type,

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

			--row_number() over (partition by sr.service_request_code, sp.perorg_code order by ss.sr_status_date) rn_person
            row_number()
            over(Partition By sr.service_request_code order by  case 
							when spt.sr_perorg_type_id = 1
								then 1
							when spt.sr_perorg_type_id = 3
								then 2
							when spt.sr_perorg_type_id = 5000009
								then 3
							when spt.sr_perorg_type_id = 11
								then 4
				end) rn_person

from 		ecbu_teamwork_sr.dbo.service_request sr

--join		(select 1 '1') i on sr.sr_type in (6,7,85)

join		ecbu_teamwork_sr.dbo.service_request_type srt on srt.sr_type = sr.sr_type 


join		ecbu_teamwork_sr.dbo.sr_item si on si.service_request_code = sr.service_request_code
										   and si.sr_item_code = 1

join		ecbu_teamwork_sr.dbo.sr_status ss on ss.sr_item = si.sr_item
											 and ss.sr_status_date between @date_start and @date_end

join		ecbu_teamwork_sr.dbo.sr_status_type sst on ss.sr_status_type = sst.sr_status_type
												   
join		ecbu_teamwork_sr.dbo.sr_perorg sp on sp.service_request_code = sr.service_request_code

join		ecbu_teamwork_sr.dbo.sr_perorg_address_details_vw spa on spa.sr_perorg = sp.sr_perorg
																 and spa.teamwork_address_type_id = 8 --Email

join		ecbu_teamwork_sr.dbo.sr_perorg_type spt on spt.sr_perorg_type_id = sp.sr_perorg_type_id
												   and spt.sr_perorg_type_id in (1, 11, 3, 5000009) --  11	Owner, 1 Agent, 3 Architect, 5000009 Engineer

join		customer.dbo.customer cu on cu.customer_number = sp.perorg_code 

where		1=1

--and			sr.service_request_code = 466103

and			(
				(	sr.sr_type in (7) and ss.sr_status_type in (3066,3071)	)		-- aBLDG CONSENT - 3066 Consent Issued, 3071 CCC Issued, 3073 Completed
			-- or  (	sr.sr_type in (6) and ss.sr_status_type in (2879)		)		-- Bldg Cons<500K - CCC Issued 
			or	(	sr.sr_type in (85) and ss.sr_status_type in (3121)		)		-- RC - a Res.Con - Issued
			-- or	(	sr.sr_type in () and ss.sr_status_type in ()		)		-- RC - a Res.Con - Issued  ****new lines here
			)

)

select		*

from		sr
where		rn_person = 1 
			---and sr.service_request_code = 366412

order by	--sr.sr_type,
		sr.service_request_code
			




--select		spt.sr_perorg_type_id,
--			spt.sr_perorg_type,
--			sp.service_request_code,
--			sp.perorg_code,
--			spa.*
--			--spa.address_code,
--			--spa.perorg_address_type,
--			--spa.full_address
			
--from		ecbu_teamwork_sr.dbo.sr_perorg_type spt
--join		ecbu_teamwork_sr.dbo.sr_perorg sp on sp.sr_perorg_type_id = spt.sr_perorg_type_id
--join		ecbu_teamwork_sr.dbo.sr_perorg_address_details_vw spa on spa.sr_perorg = sp.sr_perorg
--																 and spa.teamwork_address_type_id = 8
--where		spt.sr_perorg_type_id in (1,2,25,11)
--and			service_request_code = 67922

--and ss.sr_status_type in (3066,2879,15073502) --(2874,2879,15073502,3066,3071)