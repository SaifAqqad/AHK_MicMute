class Overlay{
    static GDI_TOKEN:=0
    , BACKGROUND_COLOR:= 0x232323
    , BACKGROUND_TRANSPARENCY:= 0xb0000000

    __New(options:=""){
        if(Overlay.GDI_TOKEN = 0){
            Overlay.GDI_TOKEN := Gdip_Startup()
            OnExit(Func("Gdip_Shutdown").bind(Overlay.GDI_TOKEN))
        }
        this.options:= options
        this.deviceContext:= CreateCompatibleDC()
        this.canvas:= CreateDIBSection(options.width, options.height, this.deviceContext)
        this.graphics:= Gdip_GraphicsFromHDC(this.deviceContext)
        this.setGraphicsOptions()
        this.backgroundBrush:= Gdip_BrushCreateSolid(Overlay.BACKGROUND_COLOR | Overlay.BACKGROUND_TRANSPARENCY)
        this.imageWidth:= options.width - 8 ; leave 8px left/right
        this.imageHeight:= options.height - 8 ; leave 8px top/bottom
        this.imageXPos:= this.imageYPos:= 4
    }

    setGraphicsOptions(){
        ; SmoothingModeAntiAlias8x8 = 6
        Gdip_SetSmoothingMode(this.graphics, 6)
        ; InterpolationModeHighQualityBicubic = 7
        Gdip_SetInterpolationMode(this.graphics, 7)
    }

    fillBackground(){
        Gdip_FillRoundedRectangle(this.graphics, this.backgroundBrush, 0, 0, this.options.width, this.options.height, 5)
    }

    drawImage(image){
        Gdip_DrawImage(this.graphics, image.bitMap
                    , this.imageXPos, this.imageYPos, this.imageWidth, this.imageHeight
                    , 0, 0, image.width, image.height)
    }

    clear(){
        Gdip_GraphicsClear(this.graphics)
    }

    dispose(){
        Gdip_DeleteBrush(this.backgroundBrush)
        DeleteObject(this.canvas)
        DeleteDC(this.deviceContext)
        Gdip_DeleteGraphics(this.graphics)
    }
}