;; loads data from a file of user selection
PRO AMOBSERVE::LOAD,event
  file = DIALOG_PICKFILE(/READ, path='./', FILTER = '*.txt',$
                         title='Select Comma Deliniated File with Name, RA, Dec')
  close,/all
  openr,12,file
  line = ''
  readf,12,line ;; skip the first line, often a dummy
  readf,12,line
  tmp = strsplit(line,',',/extract)
  if n_elementS(tmp) lt 3 then begin
     print,'Not a valid file, must be comma delimited and contain name, ra, dec, type (optional).'
  endif else begin
     if n_elements(tmp) eq 3 then begin
        readcol,file,name,ra,dec,delimiter=',',format='a,d,d',/silent
        self.ras = ptr_new(ra)
        self.decs = ptr_new(dec)
        self.names = ptr_new(name)
        self.types = ptr_new(strarr(n_elements(name)))
        stop
     endif
     if n_elements(tmp) gt 3 then begin
        readcol,file,name,ra,dec,types,delimiter=',',format='a,d,d,a',/silent
        self.ras = ptr_new(ra)
        self.decs = ptr_new(dec)
        self.names = ptr_new(name)
        self.types = ptr_new(types)
     endif
  endelse
END

pro AMOBSERVE::plot,event

  if self.ras ne ptr_new() and self.decs ne ptr_new() and self.names ne ptr_new() then begin

     cont = 1
     start = 1
     while cont eq 1 do begin
        if start eq 0 then begin
           ;; find sunset and sunrise times
           caldat,jd,mo,dy,yr,hr,mn,sec
           DELTAJD = jd-JULDAY(1,1,yr,0,0,0) ; days since jan 1, aka the SNIFS day of the year (e.g. 83, 126)
           ZENSUN, DELTAJD, 0.,obs.latitude,-1.*obs.longitude,Z,A,S,SUNRISE=SR,SUNSET=SS ; Find sunset and sunrise times (UTC hours)
           ;;later I'll figre out how to incorporate twilight, for
           ;;now twilight = 0
           twilight = 0
           hr = fix(ss+twilight)
           mn = fix((ss+twilight) - hr)*60.0
           sec = fix(((ss+twilight) - hr)*60-mn)*60.0
           TstartJD = JULDAY(mo,dy,yr,hr,mn,sec) - 1.5/24. ; it helps to have the julian dates for these variables
           hr = fix(sr-twilight)
           mn = fix((sr-twilight) - hr)*60
           sec = fix(((sr-twilight) - hr)*60-mn)*60.0
           TstopJD = JULDAY(mo,dy,yr,hr,mn,sec) ; it helps to have the julian dates for these variables
           TSTART = (SS + TWILIGHT)/24.-1.0     ; start observing time 
           TSTOP = (SR - TWILIGHT)/24.          ; end observing time
           if tstopjd lt tstartjd then tstopjd+=1.0

           xs = hangle*cos(az*!pi/180.)
           ys = hangle*sin(az*!pi/180.)
           dist = sqrt((x-xs)^2.+(y-ys)^2.)
           star = where(dist eq min(dist))
           star = star[0]

           if x gt 90 or x lt -90 or y lt -90 or y gt 90 or min(dist) gt 15 or airm[star] gt 5.0 or airm[star] lt 0.0 then begin
              cont = 0
              print,'Exiting Star Selection'
           endif else begin
              erase
              
              !p.multi=[1,1,2]
              !x.margin=[8,8]
              
              juldates = generatearray(tstartjd,tstopjd,100)
              ra = ras[star]
              dec = decs[star]
              name = names[star]
              ratmp = ra[0]+dblarr(n_elements(juldates))
              detmp = dec[0]+dblarr(n_elements(juldates))
              eq2hor,ratmp,detmp,juldates,alt,az,obsname=self.observatory

              caldat,juldates,dum1,dum2,dum3,hr,m,s
              hr = hr+(m/60.)+(s/3600.)
              local = hr-obs.tz
              if min(local) lt 0 then local+=24
              hrmarkers = [18,20,22,24,26,28,30]
              hangle = 90.0-alt
              radalt = ((hangle)*!pi/180.)
              sec = 1./cos(radalt)
              airm = sec -0.0018167*(sec-1.)-0.002875*(sec-1.)^2.-0.0008083*(sec-1.)^3.

              case self.plotstyle of 
                 0: begin
                    plot,local,alt,yrange=[0,90],xstyle=9,ystyle=9,xtitle='Local Time',ytitle='Altitude (!U0!N)',xrange=[17,31],xticks=6,xtickv=hrmarkers,xtickname=['18','20','22','0','2','4','6'],thick=4
                    if local[where(alt eq max(alt))] gt 24 then cgtext,18,80,name,charsize=1.5,charthick=2.0,alignment=0.0 else cgtext,30,80,name,charsize=1.5,charthick=2.0,alignment=1.0
                    axis,yaxis=1,xtitle='Airmass',ytickv=[60.0,53.0926,41.75,29.904,19.317864,14.276855],ytickname=['1.15','1.25','1.5','2.0','3.0','4.0'],yticks=5
                 end
                 1: begin
                    good = where(airm gt 1 and airm lt 6 and alt le 90.0 and alt gt 5)
                    plot,local[good],airm[good],yrange=[4,1],xstyle=9,ystyle=9,xtitle='Local Time',ytitle='Airmass',xrange=[17,31],xticks=6,xtickv=hrmarkers,xtickname=['18','20','22','0','2','4','6'],thick=4
                    if local[where(alt eq max(alt))] gt 24 then cgtext,18,1.3,name,charsize=1.5,charthick=2.0,alignment=0.0 else cgtext,30,1.3,name,charsize=1.5,charthick=2.0,alignment=1.0
                    axis,yaxis=1,xtitle='Altitude (!U0!N)',ytickname=['80','60','40','20'],ytickv=[1.015,1.15,1.55,2.90],yticks=3
                 end
              endcase
              tmp = hrmarkers+obs.tz
              qq = where(tmp ge 24) & if qq[0] ne -1 then tmp[qq]-=24
              xtickname = string(tmp,format="(I2)")
              axis,xaxis=1,xtitle='UT Time',xtickv=hrmarkers,xticks=6,xtickname=xtickname
              caldat,self.jd,dum1,dum2,dum3,hr,m,s
              tmp1 = hr+(m/60.)+(s/3600.0)
              tmp2 = tmp1-obs.tz
              if tmp2 lt 0 then tmp2+=24.
              oplot,[tmp2,tmp2],[0,1d5],thick=3,color=cgcolor('green'),linestyle=2

              
           endelse
        endif
        
        !x.margin = [2,2]
        !y.margin = [4,1]
        plotsym,0,/fill
        !p.multi=[0,1,2]
        ras = *self.ras
        decs = *self.decs
        names = *self.names
        types = *self.types
        
        observatory,self.observatory,obs
        jd = self.jd
        eq2hor,ras,decs,jd,alt,az,obsname=self.observatory
        hangle = 90.0-alt
        radalt = ((hangle)*!pi/180.)
        sec = 1./cos(radalt)
        airm = sec -0.0018167*(sec-1.)-0.002875*(sec-1.)^2.-0.0008083*(sec-1.)^3.
        l = where(airm lt 4. and airm gt 0 and alt gt 0)
        cgloadct,0
        if start eq 0 then noerase = 1 else noerase = 0
        az += 90.0 ;; put north up
        ;;az*=-1.0 ;; put east to the left
        Plot, hangle[l],(az[l]*!pi/180.), /Polar, XStyle=5, YStyle=5, /NoData,xrange=[-80,80],yrange=[-80,80],noerase=noerase
        Axis, /XAxis, 0, 0,xtickn=strarr(10)+' ',ytickn=strarr(10)+' '
        Axis, /YAxis, 0, 0,xtickn=strarr(10)+' ',ytickn=strarr(10)+' '
        ;; lines of constant airmass
        air125 = 90.0-53.0926
        air15 = 90.0-41.75
        air20 = 90.0-29.904
        air25 = 90.0-23.458692
        air30 = 90.0-19.317864
        air40 = 90.0-14.276855

        arrow,70,-80,60,-80,/data,thick=3
        xyouts,55,-82,'E',alignment=0.5,charsize=1.3,charthick=1.75
        arrow,70,-80,70,-70,/data,thick=3
        xyouts,70,-65,'N',alignment=0.5,charsize=1.3,charthick=1.75

        plotsym,0,/fill
        oplot,air125+dblarr(1d3),generatearray(0,2.*!pi,1d3),thick=2,color=cgcolor('green'),/polar,psym=8,symsize=0.25
        oplot,air15+dblarr(1d3),generatearray(0,2.*!pi,1d3),thick=2,color=cgcolor('teal'),/polar,psym=8,symsize=0.25
        oplot,air20+dblarr(1d3),generatearray(0,2.*!pi,1d3),thick=2,color=cgcolor('orange'),/polar,psym=8,symsize=0.25
        oplot,air30+dblarr(1d3),generatearray(0,2.*!pi,1d3),thick=2,color=cgcolor('red'),/polar,psym=8,symsize=0.25
        oplot,hangle[l],(az[l]*!pi/180.),psym=8,/polar

        ;; now for the 'types'
        uniqtypes = types[sort(types)]
        uniqtypes = uniqtypes[uniq(uniqtypes)]
        colors = [cgcolor('white'),cgcolor('blue'),cgcolor('green'),cgcolor('yellow')]
        if n_elements(uniqtypes) gt 1 and n_elements(uniqtypes) lt 5 then begin ;;please no more than 4 types for now!
           for jj = 0,n_elements(uniqtypes)-1 do begin
              good = where(types eq uniqtypes[jj] and airm lt 4. and airm gt 0 and alt gt 0)
              if good[0] ne -1 then oplot,hangle[good],(az[good]*!pi/180.),psym=8,/polar,color=colors[jj]
           endfor
           legend,uniqtypes,color=colors,psym=8,/top,/left,box=0,charthick=2.0,charsize=1.25
        endif
        
        ;; add the moon?
        if self.moon eq 1 then begin
           moonpos,jd,moonra,moondec
           eq2hor,moonra,moondec,jd,moonalt,moonaz,obsname=self.observatory
           moonangle = 90.0-moonalt
           oplot,[moonangle],[moonaz]*!pi/180.,psym=8,color=cgcolor('pink'),symsize=3.0
        endif
        
        legend,['1.25','1.50','2.00','3.00'],textcolor=[cgcolor('green'),cgcolor('teal'),cgcolor('orange'),cgcolor('red')],/bottom,/left,box=0,charthick=2.0,charsize=1.25

        if start eq 0 then begin
           plotsym,0,thick=3
           oplot,[hangle[star]],[az[star]*!pi/180.],psym=8,color=cgcolor('red'),symsize=1.2,/polar
        endif

        start = 0
        if self.refresh eq 1 then begin
           cont = 0
           self.refresh = 0
        endif
        if cont eq 1 then begin
           if start eq 1 then print,'Select a Star, click on the bottom half to exit'
           cursor,x,y
        endif
     endwhile
     
  endif else begin
     self.message = 'You need to provide data, dummy'
  endelse
END


pro AMOBSERVE::SELECT,event

  ;; not implimented yet
  
end

PRO amobserve::moon,event
  if self.moon eq 1 then begin
     print,'Turning Moon off'
     self.moon = 0
  endif else begin
     print,'Turning Moon on'
     self.moon = 1
  endelse
END

PRO amobserve::plotstyle1,event
  self.plotstyle = 1
END

PRO amobserve::plotstyle2,event
  self.plotstyle = 0
END



pro AMOBSERVE::QUIT,event
  return
end

;; I'm a bit confused on this, I think this turns a specific
;; _event code into something more generalizable, i.e., now you can
;; call amobserve::whatever instead of using a giant case
;; statement. You also have better control of what data is passed this
;; way. 
pro AMOBSERVE_Event,event
  Widget_Control, event.id, Get_UValue=info
  Call_Method, info.method, info.object, event
end

pro amobserve_Cleanup,event
  print,self.message
end

;; set the observatory
PRO amobserve::obs,event

  case event.value of
     0: self.observatory = 'mcdonald'
     1: self.observatory = 'keck'
     2: self.observatory = 'mmto'
     3: self.observatory = 'Palomar'
     else: self.observatory = 'keck'
  endcase
  print,'Observatory set to '+self.observatory

END

PRO amobserve::refresh,event

  self.refresh = 1
  jd = 1.0*systime(/julian,/utc)
  self.jd = jd
  call_method,'plot',self,event

END

PRO amobserve::date,event

  self.datestring = strtrim(string(*event.value,format="(D14.2)"),2)
  mo = 1*strmid(self.datestring,4,2)
  jdcnv,1*strmid(self.datestring,0,4),1*strmid(self.datestring,4,2),1*strmid(self.datestring,6,2),1.*strmid(self.datestring,8,5),jd
  self.jd = jd
  case mo of
     1: month = 'Jan'
     2: month = 'Feb'
     3: month = 'Mar'
     4: month = 'Apr'
     5: month = 'May'
     6: month = 'Jun'
     7: month = 'Jul'
     8: month = 'Aug'
     9: month = 'Sep'
     10: month = 'Oct'
     11: month = 'Nov'
     12: month = 'Dec'
     else: month = '??'
  endcase
  hour = 1.*strmid(self.datestring,8,5)
  hrbase = fix(hour)
  min = 60*(hour-hrbase)
  minbase = fix(min)
  print,'Time set to: '+month+' '+string(1*strmid(self.datestring,6,2),format="(I02)")+' '+string(strmid(self.datestring,0,4),format="(I4)")+$
        ' '+string(hour,format="(I2)")+':'+string(min,format="(I02)") + ' (UT)'

END


;; basic setup of the gui (which IDL calls a widget or whatever)
PRO amobserve::widget_setup

  device,retain=2
  print,'Hello, this is a simple widget designed to do a few unimportant tasts'

  ;; this setups the 'base' of the widget, i.e., buttons and things
  self.amobserve_base = WIDGET_BASE(TITLE="AWM's Obseving Tool", xsize=400,ysize=400,/FRAME) 
  
;***create quit button:***
  quit= WIDGET_BUTTON(self.amobserve_base, /FRAME, xoffset=300,yoffset=300, $
                      VALUE=' Quit ',UVALUE={object:self, method:'QUIT'})
  
;***create plot button:***
  plot= WIDGET_BUTTON(self.amobserve_base, /FRAME, xoffset=250,yoffset=300, $
                      VALUE=' Plot ',UVALUE={object:self, method:'PLOT'})
  
;***create load button:***
  load= WIDGET_BUTTON(self.amobserve_base, /FRAME, xoffset=200,yoffset=300, $
                      VALUE=' Load ',UVALUE={object:self, method:'LOAD'})

;***create select button:***
  refresh= WIDGET_BUTTON(self.amobserve_base, /FRAME, xoffset=110,yoffset=300, $
                      VALUE=' Refresh ',UVALUE={object:self, method:'Refresh'})

;***create Moon button:***
  refresh= WIDGET_BUTTON(self.amobserve_base, /FRAME, xoffset=110,yoffset=260, $
                      VALUE=' Moon ',UVALUE={object:self, method:'moon'})

;***create date field:***
  temp =  coyote_field2(self.amobserve_base,TITLE='YYYYMMDDHH.HH:', /doublevalue, $
                        UVALUE={object:self, method:'date',value:0,$
                                type: 'val', param:1 },$
                        decimal=4,/cr_only,$
                        VALUE=self.datestring, XSIZE=15,scr_ysize=30,$
                        event_pro='AMOBSERVE_Event',textid=textid)

  print,self.datestring
  ;;date = widget_Text(self.amobserve_base,$
  ;;                   VALUE = self.datestring,$
  ;;                   UVALUE={object:self, method:'DATE'},$
  ;;                   XSIZE=20,$
  ;;                   /EDITABLE, $
  ;;                   yoffset = 200)
  
  ;;widget_control,self.amobserve_base,SET_UVALUE=date


;***select observatory***
  values = ['McDonald','Maunea Kea','MMT','Palomar']
  bgroup1 = CW_BGROUP(self.amobserve_base, values, xoffset=250,/COLUMN, $
                      LABEL_TOP='Observatory', /FRAME, uvalue={object:self, method:'OBS'})


;***airmass plot style button***
  button1 = Widget_Button(self.amobserve_base, Value='Airmass',xoffset=25,yoffset=200,$
                          uvalue={object:self, method:'plotstyle1'})
  button2 = Widget_Button(self.amobserve_base, Value='Altitude',xoffset=85,yoffset=200,$
                          uvalue={object:self, method:'plotstyle2'})
  
;***Realize the menu
  WIDGET_CONTROL, self.amobserve_base, /REALIZE


  ;;WIDGET_CONTROL, self.amobserve_base,/REALIZE,/EXCLUSIVE

  
;*** Register the GUI (Hand control to X-Manager):***
  XMANAGER, 'amobserve', self.amobserve_base,/no_block,cleanup='AMOBSERVE_cleanup'


END


function amobserve::INIT,version=version,_EXTRA=ex

  self.version = version+' '
  self.observatory = 'keck'
  jd = 1.0*systime(/julian,/utc)
  self.jd = jd
  daycnv,jd,yr,mn,day,hr
  self.datestring = string(yr,format="(I4)")+string(mn,format="(I02)")+string(day,format="(I02)")+string(hr,format="(D05.2)")
  observatory,self.observatory,obs

  window,xsize=550,ysize=1100
  
  self->widget_setup
  
  return,1
  
end

pro amobserve__define
  struct = {amobserve,$
            $ ;; GENERAL STUFF
            version: '',$ 
            $                     ;; MAIN WIDGET stuff
            amobserve_base: 0L, $ ;; this is important, don't touch
            message_window: 0L, $ ;; probably leave this alone too
            message: '',$         ;; needed for error handling
            plot_windows: ptr_new(),$
            refresh:0, $        ;
            datestring:'', $    ;
            tmp:'', $           ;
            moon:0, $            ; show the moon?
            plotstyle:0, $      ; 0 = linear in alt, 1 = linear in airmass
            $                   ;; EXTRA WIDGET WINDOWS
            extra_windows: ptr_new(),$
            $ ;; WIDGET pieces
            slider: ptr_new(),$
            label_indices: ptr_new(),$
            basic_indices: ptr_new(),$
            label: ptr_new(),$
            menus: ptr_new(),$
            bases: ptr_new(),$
            settings: lonarr(6),$
            fld: lonarr(50,15),$
            fld2: lonarr(100,25),$
            numcol: 0L,$
            $ ;; parameters
            observatory:'',$
            jd:0d0,$ ;; in INIT we should default this to right now, but allow user input
            names:ptr_new(),$
            ras:ptr_new(),$
            decs:ptr_new(),$
            types:ptr_new(),$
            $ ;; END
            exists: 0L $
           }
end


PRO amobserve,_REF_EXTRA=_extra

  set_plot,'x'
  device,retain=2
  version = 'v0.1'
  amobserve = obj_new('amobserve',version=version,_EXTRA=_extra)
  
END
