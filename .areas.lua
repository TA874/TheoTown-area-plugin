local function drawOutline(x,y,w,h,s,t)
	s,t=tonumber(s) or 1,tonumber(t) or t
	local sx2,sy2=Drawing.getScale()
	local sx,sy
	w,h,sx,sy=w*sx2,h*sy2,s*sx2,s*sy2
	if type(t)~="number" or t==0 or t==1 then
		sx,sy=math.min(sx,w*0.5),math.min(sy,h*0.5)
		Drawing.drawLine(x+sx,y+(sy/2),x+(w-sx),y+(sy*0.5),sy)
		Drawing.drawLine(x+(w-(sx*0.5)),y+h-sy,x+(w-(sx*0.5)),y+sy,sx)
		Drawing.drawLine(x+(sx*0.5),y+sy,x+(sx*0.5),y+(h-sy),sx)
		Drawing.drawLine(x+w-sx,y+(h-(sy*0.5)),x+sx,y+(h-(sy*0.5)),sy)
	end
	if type(t)~="number" or t==0 or t==2 then
		sx,sy=math.min(s,w*0.5),math.min(s,h*0.5)
		Drawing.drawRect(x,y,sx,sy)
		Drawing.drawRect(x,y+h-(sy*sy2),sx,sy)
		Drawing.drawRect(x+w-(sx*sx2),y,sx,sy)
		Drawing.drawRect(x+w-(sx*sx2),y+h-(sy*sy2),sx,sy)
	end
end
local function getRectTiles(x0,y0,x1,y1,a)
	if x1<x0 and y1<y0 then
		local x=x0
		while x>=x1 do
			local y=y0
			while y>=y1 do
				pcall(function() a(x,y) end)
				y=y-1
			end
			x=x-1
		end
	end
	if x1<x0 then
		local x=x0
		while x>=x1 do
			local y=y0
			while y<=y1 do
				pcall(function() a(x,y) end)
				y=y+1
			end
			x=x-1
		end
	end
	if y1<y0 then
		local x=x0
		while x<=x1 do
			local y=y0
			while y>=y1 do
				pcall(function() a(x,y) end)
				y=y-1
			end
			x=x+1
		end
	end
	if x0<=x1 and y0<=y1 then
		local x=x0
		while x<=x1 do
			local y=y0
			while y<=y1 do
				pcall(function() a(x,y) end)
				y=y+1
			end
			x=x+1
		end
	end
end
local suc,euc
local c,xx,yy=0
local mode=-1
local editArea
local function ts(s)
	local s3=s
	pcall(function()
		local s2,mn,t="","",{}
		if type(tonumber(s))=="number"then
			s,s2=math.modf(s)
			if s<0 then mn="-" s=tostring(s):gsub(mn,"",1)end
			if s2==0 then s2=""end
		end
		s=tostring(s):reverse()
		for v in string.gmatch(s,".") do table.insert(t,v)end
		for k in pairs(t) do if k%4==0 then table.insert(t,k,",") end end
		s3=mn..(table.concat(t):reverse()..(tostring(s2):gsub("0","",1):gsub("-","",1)))
	end)
	return s3
end
local function copyTable(tbl,a,mt)
	if type(tbl)~="table" then tbl={} return end
	local tbl2={}
	for k,v in pairs(tbl) do
		tbl2[k]=v
		if type(a)=="function" then tbl2[k]=a(v) end
	end
	if mt then setmetatable(tbl2,getmetatable(tbl)) end
	return tbl2
end
local function reverseTable(tbl,a,mt)
	if type(tbl)~="table" then tbl={} return end
	local tbl2={}
	for _,v in ipairs(tbl) do table.insert(tbl2,1,v) end
	for k,v in pairs(tbl) do if not tonumber(k) then tbl2[k]=v end end
	if mt then setmetatable(tbl2,getmetatable(tbl)) end
	return tbl2
end
local function updateAreaXY(area)
	local coverage=area.coverage
	if #coverage<1 then return end
	local w,h=City.getWidth()-1,City.getHeight()-1
	local startX,startY,endX,endY=w,h,0,0
	for _,v in pairs(area.coverage) do
		local x,y=tonumber(v.x),tonumber(v.y)
		startX,startY=math.min(startX,x),math.min(startY,y)
		endX,endY=math.max(endX,x),math.max(endY,y)
	end
	area.x,area.y=(startX*0.5)+(endX*0.5),(startY*0.5)+(endY*0.5)
	for _,c in pairs(coverage) do
		local x,y=tonumber(c.x),tonumber(c.y)
		local dirs={}
		local function fXY(x,y)
			local e,v
			local fl=math.floor
			for _,vv in ipairs(area.coverage) do e=(fl(vv.x)==fl(x)) and (fl(vv.y)==fl(y)) if e then v=tostring(vv) break end end
			return v
		end
		dirs.S=fXY(x+1,y) dirs.SE=fXY(x+1,y+1)
		dirs.E=fXY(x,y+1) dirs.NE=fXY(x-1,y+1)
		dirs.N=fXY(x-1,y) dirs.NW=fXY(x-1,y-1)
		dirs.W=fXY(x,y-1) dirs.SW=fXY(x+1,y-1)
		c.dirs=dirs
	end
	area.new,area.new2=nil,nil
end
local function loadAreas()
	local areas={}
	CityAreas=areas
	local areas0=Util.optStorage(City.getStorage(),script:getDraft():getId())
	for i,area in ipairs(areas0) do table.insert(areas,Runtime.fromJson(area)) end
	for i,area in ipairs(areas) do
		local a=area.coverage
		local a2={}
		for i in pairs(a) do a2[tonumber(i)]=a[i] end
		table.sort(a2,function(a,b) return (a.y+a.x)<(b.y+b.x) end)
		area.coverage=a2
		updateAreaXY(area)
	end
	editArea=nil
	table.sort(areas,function(a,b) return a.ordinal<b.ordinal end)
	local i
	while next(areas,i) do
		i=(tonumber(i) or 0)+1
		local area=areas[i]
		if #area.coverage==0 then table.remove(CityAreas,i) i=i-1 if i==0 then i=nil end end
		area.ordinal=i
	end
end
local function saveAreas()
	local areas0=Util.optStorage(City.getStorage(),script:getDraft():getId())
	while next(areas0) do table.remove(areas0) end
	for i,area in ipairs(CityAreas) do areas0[i]=Runtime.toJson(area) end
end
local function deleteArea(area)
	if type(area)~="table" then return end
	local str=tostring
	for i,area0 in pairs(CityAreas) do if str(area0)==str(area) then table.remove(CityAreas,i) break end end
	area,c,xx,yy=nil,0,nil,nil
end
local registerToolAction
local function newArea()
	c,xx,yy=0
	if type(editArea)=="table" then editArea.new=nil end
	local rdm=math.random
	editArea={
		ordinal=#CityAreas+1,
		name="",
		textSize="BIG",
		textColor={r=255,g=255,b=255},
		color={r=rdm(0,255),g=rdm(0,255),b=rdm(0,255)},
		coverage={},
		new=true,new2=true
	}
	local r=City.getRotation()
	local w,h=City.getWidth()-1,City.getHeight()-1
	local x,y=City.getView()
	if r==1 or r==2 then y=h-y end
	if r==3 or r==2 then x=w-x end
	if r==1 or r==3 then x,y=y,x end
	editArea.x=math.floor(math.max(0,math.min(x+0.5,w)))
	editArea.y=math.floor(math.max(0,math.min(y+0.5,h)))
	mode=0
end
local function openAreaEditDialog(area)
	if type(area)~="table" then return end
	local oldName=area.name local name=oldName
	local oldFont=area.textSize local font=oldFont
	local oc=copyTable(area.color) local nc=copyTable(oc)
	local otc=copyTable(area.textColor) local ntc=copyTable(otc)
	local openColorDialog,tf
	do local tab=0 openColorDialog=function()
		local dialog=GUI.createDialog {w=180,h=166,onClose=function() tf:setVisible(true) end}
		dialog.content:addLayout {
			vertical=true,
			onInit=function(self)
				local tabs=self:addLayout {h=30,y=32}
				for i,k in pairs{"Area","Text"} do local b b=tabs:addButton {
					w=(tabs:getW()/2),
					text=k,
					isPressed=function() return (b:getTouchPoint() and true) or math.floor(tab+0.5)==i-1 end,
					onClick=function() tab=i-1 end
				} end
				self:addCanvas {h=30,onDraw=function(self,x,y,w,h)
					local r,g,b=Drawing.getColor()
					Drawing.setColor((ntc.r*tab)+(nc.r*(1-tab)),(ntc.g*tab)+(nc.g*(1-tab)),(ntc.b*tab)+(nc.b*(1-tab)))
					Drawing.drawRect(x,y,w,h)
					Drawing.setColor(0,0,0)
					drawOutline(x,y,w,h)
					Drawing.setColor(r,g,b)
				end}
				for i,k in pairs{"r","g","b"} do
					self:addCanvas {h=20}
					:addLabel {w=10,text=k:upper(),onUpdate=function(self)
						local tbl={0,0,0}
						tbl[i]=200
						self:setColor(table.unpack(tbl))
					end}
					:getPa():addSlider {
						x=10,
						minValue=0,
						maxValue=255,
						getText=function() return math.floor((ntc[k]*tab)+(nc[k]*(1-tab))) end,
						getValue=function() return (ntc[k]*tab)+(nc[k]*(1-tab)) end,
						setValue=function(cc)
							if tab<0.5 then nc[k]=cc end
							if tab>=0.5 then ntc[k]=cc end
						end,
					}
				end
			end
		}
		do
			local gi
			pcall(function() gi=giIsEnabled() end)
			if not gi then Runtime.postpone(function() tf:setVisible(false) end) end
		end
		return dialog
	end end
	local dialog=GUI.createDialog {
		title="Edit area",
		w=230,h=130,
		actions={icon=Icon.CANCEL,text="Cancel"}
	}
	tf=dialog.content:addTextField{h=30,onUpdate=function(self) name=self:getText() end}
	tf:setText(oldName)
	local fontSelection=dialog.content:addLayout{h=20,y=32}
	for _,f in pairs{"SMALL","DEFAULT","BIG"} do local b b=fontSelection:addButton {
		w=20,h=20,
		text="A",
		isPressed=function() return (b:getTouchPoint() or font==f) and true end,
		onClick=function() font=f end,
		onInit=function(self) self:setFont(Font[f]) end,
	} end
	dialog.controls:addCanvas {
		w=30,
		onClick=function() playClickSound() openColorDialog() end,
		onDraw=function(self,x,y,w,h)
			local r,g,b=Drawing.getColor()
			pcall(function() Drawing.setColor(giGetColor()) end)
			Drawing.drawRect(x,y,w,h)
			local a=Drawing.getAlpha()
			Drawing.setColor(0,0,0)
			pcall(function() Drawing.setColor(giAutoGetColor()) end)
			if not (self:getTouchPoint() or self:isMouseOver()) then Drawing.setAlpha(a*0.7) end
			drawOutline(x,y,w,h)
			if self:isTouchPointInFocus() then
				Drawing.setAlpha(a*0.3)
				Drawing.drawRect(x,y,w,h)
				Drawing.setAlpha(a)
			end
			x,y,w,h=x+4,y+4,w-8,h-8
			local function dt(ii,...)
				Drawing.drawTriangle(...)
				local r,g,b=Drawing.getColor()
				Drawing.setColor(255,255,255)
				if (r+g+b)/3>=127.5 then Drawing.setColor(0,0,0) end
				if ii==1 then
					Drawing.setClipping(x,y,1,h)
					Drawing.drawTriangle(...)
					Drawing.setClipping(x,y+h-1,w,1)
					Drawing.drawTriangle(...)
				end
				if ii==2 then
					Drawing.setClipping(x+w-1,y,1,h)
					Drawing.drawTriangle(...)
					Drawing.setClipping(x,y,w,1)
					Drawing.drawTriangle(...)
				end
				Drawing.resetClipping()
				Drawing.setColor(r,g,b)
			end
			Drawing.setColor(nc.r,nc.g,nc.b)
			dt(1,x,y,x,y+h,x+w,y+h)
			Drawing.setColor(ntc.r,ntc.g,ntc.b)
			dt(2,x,y,x+w,y,x+w,y+h)
			Drawing.setColor(r,g,b)
		end,
	}
	dialog.controls:getLastPart():addButton {
		w=0,
		icon=Icon.SAVE,
		text="Save",
		golden=true,
		onClick=function()
			area.name=name
			area.textSize=font
			for k,v in pairs(nc) do area.color[k]=v end
			for k,v in pairs(ntc) do area.textColor[k]=v end
		end,
		onUpdate=function(self)
			local cm=nc.r~=oc.r or nc.g~=oc.g or nc.b~=oc.b
				or ntc.r~=otc.r or ntc.g~=otc.g or ntc.b~=otc.b
			self:setEnabled(name:len()>=1 and (cm or name~=oldName or font~=oldFont))
		end,
	}
	return dialog
end
local function openPropertiesDialog(area)
	if type(area)~="table" then return end
	local dialog=GUI.createDialog {w=230,title=area.name}
	local text=Translation.statistics_buildings..": "
	local buildings={}
	for _,v in pairs(area.coverage) do
		local ts=tostring
		local x,y=v.x,v.y
		local building=Tile.getBuilding(x,y)
		local e
		for _,v in pairs(buildings) do e=ts(v)==ts(building) if e then break end end
		if not e then table.insert(buildings,building) end
	end
	text=text..ts(#buildings).."\n"
	local population={0,0,0}
	local workers={0,0,0}
	for _,building in pairs(buildings) do
		local draft=Tile.getBuildingDraft(building:getXY())
		if draft:isRCI() then
			local level=draft.orig.level
			if draft:isResidential() then
				population[level]=population[level]+tonumber(draft.orig.habitants) or 0
			else
				workers[level]=workers[level]+tonumber(draft.orig.workers) or 0
			end
		end
	end
	for i=1,3 do text=text.."\n"..tostring(Translation["ci_general_population"..(i-1)]):gsub("% %%1%$,d"," "..ts(population[i])) end
	text=text.."\n"
	for i,v in pairs{"Poor","Middle","Rich"} do text=text.."\n"..v.." workers ("..("₮"):rep(i).."): "..ts(workers[i]) end
	text=text.."\n"
	dialog.content:addTextFrame {text=text}
	return dialog
end
local function addToolbar()
	pcall(function() cArToolbar:delete() end)
	cArToolbar=GUI.getRoot():addCanvas {
		w=25,x=-25,y=30,
		onInit=function(self)
			local x,h=self:getX(),self:getH()
			local function update()
				local ss=GUI.get("sidebarLine")
				if type(ss)=="table" then if ss:getAX()+ss:getW()>=self:getAX() then self:setX(x-ss:getW()) end end
				local mm=GUI.get("cmdMinimap")
				if type(mm)=="table" then if mm:getAX()+mm:getW()>=self:getAX() then self:setH(h-mm:getH()) end end
			end
			update()
			Runtime.postpone(function() update() end)
		end,
		onUpdate=function(self)
			for ii=0,2 do
				local w,ww,h=0,0,0 for i,c in pairs(self:getObjects()) do
					w=math.max(w,c:getW())
					c:setX(self:getW()-c:getW()-ww)
					c:setY(h)
					h=h+c:getH()
					if h>self:getH()-c:getH() then ww=ww+w w,h=0,0 end
				end
				self:setW(w+ww)
			end
			self:setX(self:getPa():getCW()-self:getW())
			local ss=GUI.get("sidebarLine")
			if type(ss)=="table" then if ss:getAX()+ss:getW()>=self:getAX() then self:setX(self:getX()-ss:getW()) end end
			if not cArIsToolOpen then self:delete() end
		end,
		onDraw=function(self,x,y,w,h) drawOutline(x,y,w,h,0.1) end
	}
	registerToolAction=function(tbl)
		local h0=25
		local isVisible=type(tbl.isVisible)=="function" and tbl.isVisible or function() return true end
		local isPressed=type(tbl.isPressed)=="function" and tbl.isPressed or function() end
		if not isVisible() then h0=0 end
		local h1,h2=h0,h0
		local tt=Runtime.getTime()
		return cArToolbar:addCanvas {
			h=h0,w=100,
			onInit=function(self)
				self:setTouchThrough(true)
				self:addCanvas {
					w=25,
					onClick=function() playClickSound() if type(tbl.onClick)=="function" then tbl.onClick() end end,
					onUpdate=function(self) self:setH(self:getPa():getH()) end,
					onDraw=function(self,x,y,w,h,...)
						if h<=0 then return end
						local ip=isPressed()
						local a=Drawing.getAlpha()
						Drawing.setAlpha(a*(h/26))
						Drawing.setClipping(x,y,w,h)
						local yo,np=-1,NinePatch.BUTTON
						local gtp=self:getTouchPoint()
						if (gtp and not ip) or (ip and not gtp) then yo,np=1,NinePatch.BUTTON_DOWN end
						Drawing.drawNinePatch(np,x,y,w,h)
						local icon=tonumber(tbl.icon) or 0
						local iw,ih=Drawing.getImageSize(icon)
						Drawing.drawImage(icon,x+(w/2)-(iw/2),yo+y+(h/2)-(ih/2))
						if type(tbl.onDraw)=="function" then tbl.onDraw(self:getPa(),x,y+yo,w,h,...) end
						Drawing.resetClipping()
						Drawing.setAlpha(a)
					end
				}
				self:addCanvas {
					onUpdate=function(self) self:setH(self:getPa():getH()) end,
					onInit=function(self)
						local text=tbl.name
						text=tostring(text or text==nil and "")
						local tw,th=Drawing.getTextSize(text)
						self:setW(tw+6)
					end,
					onDraw=function(self,x,y,w,h)
						if h<=0 then return end
						local a=Drawing.getAlpha()
						Drawing.setAlpha(a*(h/26))
						local text=tbl.name
						text=tostring(text or text==nil and "")
						local tw,th=Drawing.getTextSize(text,Font.SMALL)
						self:setW(tw+6)
						w=self:getW()
						Drawing.setClipping(x,y,w,h)
						do
							local x=x+(w/2)-(tw/2)
							local function draw(xx,yy) Drawing.drawText(text,xx+x,yy+y+(h/2)-(th/2),Font.SMALL) end
							local r,g,b=Drawing.getColor()
							Drawing.setColor(0,0,0)
							for _,i in pairs{0.5,0.4,0.3,0.2,0.1} do
								draw(i,0) draw(-i,0) draw(0,-i) draw(0,i)
								draw(i,i) draw(-i,i) draw(i,-i) draw(-i,-i)
							end
							Drawing.setColor(r,g,b)
							if isPressed() then Drawing.setColor(100*(r/255),220*(g/255),200*(b/255)) end
							draw(0,0)
							Drawing.setColor(r,g,b)
						end
						Drawing.resetClipping()
						Drawing.setAlpha(a)
					end
				}:setTouchThrough(true)
			end,
			onUpdate=function(self)
				if isVisible() then h0=25 else h0=0 end
				if h1~=h0 then
					h2,h1=h1,h0
					local ti=500*(math.abs(h2-h1)/26)
					local ttt=(Runtime.getTime()-tt)/ti
					ttt=math.max(0,math.min(ttt,1))
					tt=Runtime.getTime()-(ti*(1-ttt))
				end
				local ti=500*(math.abs(h2-h1)/26)
				local ttt=(Runtime.getTime()-tt)/ti
				ttt=math.max(0,math.min(ttt,1))
				self:setH((h2*(1-ttt))+(h1*ttt))
				local w=0 for _,c in pairs(reverseTable(self:getObjects())) do c:setX(w) w=w+c:getW() end
				self:setW(w)
			end,
		}
	end
	cArToolbar:setTouchThrough(true)
end
local function registerToolActions()
	registerToolAction {
		icon=Icon.PLUS,
		name="New area",
		onClick=function() newArea() end,
	}
	registerToolAction {
		icon=Icon.EDIT,
		name="Edit area",
		isVisible=function() return type(editArea)=="table" and true end,
		onClick=function() openAreaEditDialog(editArea) end,
	}
	registerToolAction {
		icon=Icon.ABOUT,
		name="Properties",
		isVisible=function() return type(editArea)=="table" and true end,
		onClick=function(...) openPropertiesDialog(editArea) end,
	}
	registerToolAction {
		icon=Icon.REMOVE,
		name="Delete area",
		isVisible=function() return type(editArea)=="table" and true end,
		onClick=function() deleteArea(editArea) end,
	}
	registerToolAction {
		icon=Icon.PLUS,
		name="Expand",
		isVisible=function() return type(editArea)=="table" and true end,
		isPressed=function() return mode==0 end,
		onClick=function(...) if mode~=0 then mode=0 else mode=-1 end end,
	}
	registerToolAction {
		icon=Icon.REMOVE,
		name="Erase",
		isVisible=function()
			if type(editArea)~="table" then return false end
			return #editArea.coverage>=1 and true
		end,
		isPressed=function() return mode==1 end,
		onClick=function(...) if mode~=1 then mode=1 else mode=-1 end end,
	}
	registerToolAction {
		icon=Icon.REMOVE,
		name="Hard erase",
		isVisible=function() return #CityAreas>=1 end,
		isPressed=function() return mode==2 end,
		onClick=function(...) if mode~=2 then mode=2 else mode=-1 end end,
	}
	registerToolAction {
		icon=Icon.CANCEL,
		name="Cancel",
		isVisible=function() return type(editArea)=="table" and true end,
		onClick=function(...)
			editArea.new=nil
			if not (tonumber(editArea.x) and tonumber(editArea.y)) then deleteArea(editArea) end
			c,editArea,xx,yy=0
		end,
	}
end
function script:enterCity() loadAreas() end
function script:buildCityGUI() if cArIsToolOpen then addToolbar() registerToolActions() end end
function script:leaveCity()
	if type(editArea)=="table" then editArea.new=false end
	cArIsToolOpen,CityAreas,editArea=nil
end
function script:event(_,_,_,event)
	if event==Script.EVENT_TOOL_ENTER then
		if type(CityAreas)~="table" then loadAreas() end
		cArIsToolOpen=true
		addToolbar()
		registerToolActions()
		cArSetToolFilter=TheoTown.setToolFilter
		cArSetToolFilter{mouse=true}
	end
	if event==Script.EVENT_TOOL_LEAVE then
		pcall(function() cArToolbar:delete() end)
		cArIsToolOpen,cArSetToolFilter=nil
		if type(editArea)=="table" then editArea.new=nil end
		mode,c,editArea,xx,yy=-1,0
	end
end
function script:drawCity()
	if Runtime.getStageName()~="GameStage" then return end
	local r=City.getRotation()
	local w,h=City.getWidth(),City.getHeight()
	for _,area in ipairs(CityAreas) do
		local _,_,s=City.getView()
		Drawing.setScale(s,s)
		local dc=area.color
		for _,v in ipairs(area.coverage) do
			local x,y=v.x,v.y
			local dirs=type(v.dirs)=="table" and v.dirs or {}
			local fl=math.floor
			Drawing.setColor(dc.r,dc.g,dc.b)
			Drawing.setTile(x,y)
			if cArIsToolOpen then
				Drawing.setAlpha(0.2)
				if tostring(area)==tostring(editArea) then
					local ii=(Runtime.getTime()%2000)/1000
					if ii>1 then ii=2-ii end
					Drawing.setAlpha(0.6*ii)
				end
				Drawing.drawTileFrame(Icon.TOOLMARK+16+8)
				Drawing.setAlpha(1)
			end
			local function dl(f) Drawing.drawTileFrame(Draft.getDraft("$areas01"):getFrame(f)) end
			local a=Drawing.getAlpha()
			if not cArIsToolOpen then Drawing.setAlpha(a*0.3) end
			
			if not dirs.N then dl(1+((1+(r-1))%4)) end
			if not dirs.E then dl(1+((2+(r-1))%4)) end
			if not dirs.S then dl(1+((3+(r-1))%4)) end
			if not dirs.W then dl(1+((4+(r-1))%4)) end
			
			if dirs.N and dirs.W and not dirs.NW then dl(5+((1+(r-1))%4)) end
			if dirs.N and dirs.E and not dirs.NE then dl(5+((2+(r-1))%4)) end
			if dirs.S and dirs.E and not dirs.SE then dl(5+((3+(r-1))%4)) end
			if dirs.S and dirs.W and not dirs.SW then dl(5+((4+(r-1))%4)) end
			Drawing.setAlpha(a)
		end
		Drawing.setColor(255,255,255)
		if tonumber(area.x) and tonumber(area.y) then
			local x,y=area.x,area.y
			Drawing.setTile(x,y)
			if cArIsToolOpen and tostring(area)==tostring(editArea) then
				local ii=(Runtime.getTime()%2000)/1000
				if ii>1 then ii=2-ii end
				Drawing.setAlpha(1-ii)
				Drawing.drawTileFrame(Icon.TOOLMARK+16+8)
				Drawing.setAlpha(ii)
			end
			local text=area.name
			local font=Font[area.textSize]
			local tw,th=Drawing.getTextSize(text,font)
			local function draw(xx,yy) Drawing.drawText(text,xx+(16*s)-(tw/2),yy-(th/2),font) end
			local sx,sy=Drawing.getScale()
			Drawing.setScale(1,1)
			local r,g,b=Drawing.getColor()
			Drawing.setColor(0,0,0)
			local a=Drawing.getAlpha()
			Drawing.setAlpha(a/16)
			for _,i in pairs{1,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1} do
				draw(i,0) draw(-i,0) draw(0,-i) draw(0,i)
				draw(i,i) draw(-i,i) draw(i,-i) draw(-i,-i)
			end
			local tc=area.textColor
			Drawing.setColor(tc.r,tc.g,tc.b)
			Drawing.setAlpha(a)
			draw(0,0)
			if cArIsToolOpen then
				local text=area.ordinal
				local tw,th2=Drawing.getTextSize(text,Font.BIG)
				local x=(16*s)-(tw/2)
				local y=-(th/2)-th2-4
				Drawing.setAlpha(1)
				Drawing.setColor(dc.r,dc.g,dc.b)
				Drawing.drawRect(x-2,y,tw+4,th2)
				do
					local r,g,b=Drawing.getColor()
					local c=r+g+b
					Drawing.setColor(0,0,0)
					if (c/3)<=127.5 then Drawing.setColor(255,255,255) end
				end
				drawOutline(x-3,y,tw+6,th2)
				Drawing.drawText(text,x,y,Font.BIG) 
			end
			Drawing.setColor(r,g,b)
			Drawing.setScale(sx,sy)
		end
	end
end
function script:draw(x,y,x0,y0)
	local pl=Runtime.getPlatform()
	if c==1 then
		if pl~="desktop" then
			local r=City.getRotation()
			local w,h=City.getWidth()-1,City.getHeight()-1
			x0,y0=City.getView()
			if r==1 or r==2 then y0=h-y0 end
			if r==3 or r==2 then x0=w-x0 end
			if r==1 or r==3 then x0,y0=y0,x0 end
		end
		if (x>=xx and y>=yy and x<=x0+0.5 and y<=y0+0.5)
		or (x>=xx and y<=yy and x<=x0+0.5 and y>=y0-0.5)
		or (x<=xx and y>=yy and x>=x0-0.5 and y<=y0+0.5)
		or (x<=xx and y<=yy and x>=x0-0.5 and y>=y0-0.5) then
			local fl=math.floor
			if (pl~="android") or (fl(x)==fl(x0+0.5) and fl(y)==fl(y0+0.5)) then
				local a=Drawing.getAlpha()
				if (fl(x)~=fl(x0+0.5) or fl(y)~=fl(y0+0.5)) then Drawing.setAlpha (a*0.3) end
				Drawing.setTile(x,y)
				Drawing.drawTileFrame(Icon.TOOLMARK+17)
				Drawing.setAlpha(a)
			end
		end
		if x==xx and y==yy then Drawing.setTile(x,y) Drawing.drawTileFrame(Icon.TOOLMARK+16) end
	elseif pl=="desktop" and x==x0 and y==y0 then Drawing.setTile(x,y) Drawing.drawTileFrame(Icon.TOOLMARK+16) end
end
function script:click(x,y)
	if type(CityAreas)~="table" then mode,c,editArea=0,-1 loadAreas() return end
	if mode==-1 then
		if type(editArea)=="table" then editArea.new=nil end
		local area0
		for _,area in pairs(CityAreas) do
			local e
			local fl=math.floor
			for _,v in ipairs(area.coverage) do
				e=fl(v.x)==fl(x) and fl(v.y)==fl(y)
				if e then break end
			end
			e=e or (fl(area.x)==fl(x) and fl(area.y)==fl(y))
			if e then area0=area end
		end
		if tostring(editArea)==tostring(area0) then editArea=nil else editArea=area0 end
		return
	end
	local w,h=City.getWidth()-1,City.getHeight()-1
	c=c+1
	if c==1 then cArSetToolFilter{land=true,water=true,building=true,road=true,mouse=true} xx,yy=x,y end
	if c==2 then
		cArSetToolFilter{mouse=true} c=0
		c=0
		if suc then suc(xx,yy,x,y,x,y) end
		getRectTiles(xx,yy,x,y,function(x,y)
			if mode==0 then
				local fl,e=math.floor
				for _,v in pairs(editArea.coverage) do e=e or (fl(v.x)==fl(x) and fl(v.y)==fl(y)) end
				if not e then table.insert(editArea.coverage,{x=x,y=y}) end
			end
			if mode==1 or mode==2 then
				local function erase(area)
					for i,v in pairs(area.coverage) do
						local fl=math.floor
						if fl(v.x)==fl(x) and fl(v.y)==fl(y) then table.remove(area.coverage,i) break end
					end
				end
				if mode==1 then erase(editArea) end
				if mode==2 then for _,area in pairs(CityAreas) do erase(area) end end
			end
		end)
		if mode==0 or mode==1 then updateAreaXY(editArea) end
		if mode==2 then for _,area in pairs(CityAreas) do updateAreaXY(area) end end
		if euc then euc() end
		xx,yy=nil,nil
	end
end
function script:overlay()
	if type(City)~="table" then return end
	if type(CityAreas)~="table" then mode,c,editArea=-1,-1 loadAreas() end
	local o=script:getDraft().orig
	if type(editArea)=="table" and editArea.new2 then table.insert(CityAreas,editArea) end
	table.sort(CityAreas,function(a,b) return a.ordinal<b.ordinal end)
	local i,e
	while next(CityAreas,i) do
		i=(tonumber(i) or 0)+1
		local area=CityAreas[i]
		area.new=area.new and cArIsToolOpen
		if not area.new then area.new=nil end
		if #area.coverage==0 and not area.new then table.remove(CityAreas,i) i=i-1 if i==0 then i=nil end break end
		area.ordinal=i
		if not e then e=tostring(area)==tostring(editArea) end
	end
	if type(editArea)=="table" then
		if #editArea.coverage==0 and mode==1 then mode=-1 end
		if mode==-1 then c=0 end
		if editArea.new2 then
			editArea.name="Area "..(#CityAreas)
			editArea.new2=nil
			return
		end
		if not e then editArea=nil end
	else if mode~=2 then mode=-1 end end
	if cArIsToolOpen and Runtime.getStageName()=="GameStage" then o.title="Areas ("..#CityAreas..")" else o.title="Areas" end
	saveAreas()
end
