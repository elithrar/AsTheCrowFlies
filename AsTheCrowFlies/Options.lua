local _,N=...;local O={};N.Options=O
-- SND owns the dialog, tabs, controls, profile commands and transient editors.
function O:Declare(app)
    local function choices(values) local out={};for _,v in ipairs(values) do out[#out+1]={value=v[1],label=v[2]} end;return out end
    local function preview(key) return function(color)
        if not N.UI.owner then return end
        local saved=app:Get('colors.'..key);local same=true
        for i=1,3 do if saved[i]~=color[i] then same=false end end
        N.UI.previewColors=N.UI.previewColors or {};N.UI.previewColors[key]=not same and color or nil
        N.UI:ApplyAppearance()
    end end
    self.panel=app:Options({title='As The Crow Flies',pages={
        {id='appearance',label='Appearance',sections={{title='Appearance',controls={
            {type='select',key='theme',label='Theme',choices=function()return app.ui:Themes()end},
            {type='font',key='font',label='Font'},
            {type='slider',key='fontSize',label='Font size',step=1},
            {type='slider',key='scale',label='Island scale',step=.01,format='percent'},
            {type='color',key='colors.background',label='Background',preview=preview('background')},
            {type='color',key='colors.text',label='Text',preview=preview('text')},
        }}}},
        {id='navigation',label='Navigation',sections={{title='Navigation',controls={
            {type='select',key='routeOrder',label='Route order',choices=choices({{'distance','Distance'},{'time','Estimated time'}})},
            {type='checkbox',key='mapMarkers',label='World / zone map markers'},
            {type='checkbox',key='minimapMarkers',label='Minimap markers'},
        }}}},
        {id='position',label='Position',sections={{title='Position',controls={
            {type='checkbox',key='locked',label='Lock position'},
            {type='select',key='dock',label='Screen edge',choices=choices({{'none','Free (dragged)'},{'left','Left screen edge'},{'right','Right screen edge'}})},
            {type='select',key='strata',label='Frame layer',choices=choices({{'LOW','Low'},{'MEDIUM','Medium'},{'HIGH','High'}})},
            {type='button',label='Reset placement',action=function() N.Core:SetPreferences({x=24,y=-180,dockPosition=.5,dock='none'}) end},
            {type='button',label='Expand / tuck',action=function()N.UI:Toggle(N.Core)end},
            {type='button',label='Show panel',action=function()N.Core:ShowPanel(true)end},
            {type='button',label='Hide panel',action=function()N.Core:ShowPanel(false)end},
        }}}},N.SomethingNeedDoing.Pages.Profiles(),
    }})
end
function O:Open(page)
    if N.UI.menu then N.UI.menu:Hide() end
    local ok,err=self.panel:Open(page);self.frame=self.panel.frame
    if not ok then N.App.log:Warn(err.message) end
    return ok,err
end
function O:Toggle() if self.panel:IsShown() then return self.panel:Close() else return self:Open() end end
function O:RefreshPlacement() return self.panel:Refresh() end
