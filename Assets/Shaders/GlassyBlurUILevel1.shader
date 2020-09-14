
Shader "Custom/Glass Blur UI Level1"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent+0"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

		GrabPass{ }
        Pass
        {
            Name "Default"
        CGPROGRAM
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
//#pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            
            #define screenSizeX _ScreenParams.x
            #define screenSizeY _ScreenParams.y
            
            #define GaussianBlur GaussianBlurLevel1

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
		    uniform sampler2D _GrabTexture;
            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;


            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _Color;
                return OUT;
            }
            
            
		inline float4 m_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = 1.0;
			#else
			float scale = -1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}
            
            //I've calculated the Gaussian rate using the tool on http://dev.theomader.com/gaussian-kernel-calculator/
            inline half4 GaussianBlurLevel1(float2 pos) 
            {
                static const float2 texcoordOffset[25] = {
float2(-2/screenSizeX, -2/screenSizeY),float2(-2/screenSizeX, -1/screenSizeY),float2(-2/screenSizeX, 0/screenSizeY),float2(-2/screenSizeX, 1/screenSizeY),float2(-2/screenSizeX, 2/screenSizeY),
float2(-1/screenSizeX, -2/screenSizeY),float2(-1/screenSizeX, -1/screenSizeY),float2(-1/screenSizeX, 0/screenSizeY),float2(-1/screenSizeX, 1/screenSizeY),float2(-1/screenSizeX, 2/screenSizeY),
float2(0/screenSizeX, -2/screenSizeY),float2(0/screenSizeX, -1/screenSizeY),float2(0/screenSizeX, 0/screenSizeY),float2(0/screenSizeX, 1/screenSizeY),float2(0/screenSizeX, 2/screenSizeY),
float2(-1/screenSizeX, -2/screenSizeY),float2(1/screenSizeX, -1/screenSizeY),float2(1/screenSizeX, 0/screenSizeY),float2(1/screenSizeX, 1/screenSizeY),float2(1/screenSizeX, 2/screenSizeY),
float2(-2/screenSizeX, -2/screenSizeY),float2(2/screenSizeX, -1/screenSizeY),float2(2/screenSizeX, 0/screenSizeY),float2(2/screenSizeX, 1/screenSizeY),float2(2/screenSizeX, 2/screenSizeY),
};
            
            
                return 
0.003765 * tex2D(_GrabTexture,pos+texcoordOffset[0]) + 	0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[1]) +	0.023792 * tex2D(_GrabTexture,pos+texcoordOffset[2]) +	0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[3]) +	0.003765 * tex2D(_GrabTexture,pos+texcoordOffset[4]) +
0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[5]) + 	0.059912 * tex2D(_GrabTexture,pos+texcoordOffset[6]) +0.094907 * tex2D(_GrabTexture,pos+texcoordOffset[7]) +	0.059912 * tex2D(_GrabTexture,pos+texcoordOffset[8]) +0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[9]) +
	0.023792 * tex2D(_GrabTexture,pos+texcoordOffset[10]) + 0.094907 * tex2D(_GrabTexture,pos+texcoordOffset[11]) +	0.150342 * tex2D(_GrabTexture,pos+texcoordOffset[12]) + 0.094907 * tex2D(_GrabTexture,pos+texcoordOffset[13]) +	0.023792 * tex2D(_GrabTexture,pos+texcoordOffset[14]) +
0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[15]) +	0.059912 * tex2D(_GrabTexture,pos+texcoordOffset[16]) +0.094907 * tex2D(_GrabTexture,pos+texcoordOffset[17]) +	0.059912 * tex2D(_GrabTexture,pos+texcoordOffset[18]) +0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[19]) +
0.003765 * tex2D(_GrabTexture,pos+texcoordOffset[20]) + 0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[21]) +	0.023792 * tex2D(_GrabTexture,pos+texcoordOffset[22]) +0.015019 * tex2D(_GrabTexture,pos+texcoordOffset[23]) +0.003765 * tex2D(_GrabTexture,pos+texcoordOffset[24]) ;

            }
            inline half4 GaussianBlurLevel2(float2 pos) 
            {
                return half4(0,0,0,0);
            }
            inline half4 GaussianBlurLevel3(float2 pos) 
            {
                return half4(0,0,0,0);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                //float4 grabScreenPos = m_ComputeGrabScreenPos( float4(IN.texcoord.xy,0,1) );
                
                float4 grabScreenPos = m_ComputeGrabScreenPos( float4(IN.vertex.x/_ScreenParams.x,IN.vertex.y/_ScreenParams.y,0,1) );
			    float4 grabScreenPosNorm = grabScreenPos / grabScreenPos.w;
                half4 color = (tex2D(_MainTex, IN.texcoord) *  GaussianBlur(float2(grabScreenPos.x, grabScreenPos.y))) * IN.color;
                color.a=1;
                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif
                //return tex2D(_MainTex,IN.vertex.xy);
                return color;
            }
        ENDCG
        }
    }
}