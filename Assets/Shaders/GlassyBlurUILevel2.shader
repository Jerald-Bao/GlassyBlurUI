

/// Authored by Jerald Bao

Shader "Custom/Glass Blur UI Level2"
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
        //ColorMask [_ColorMask]

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
            
            #define GaussianBlur GaussianBlurLevel2

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
            inline fixed4 GaussianBlurLevel2(float2 pos) 
            {
                static const int radius=5;
                fixed4 buffer[radius*(radius+1)/2];
                int bufferIndex=0;
                for (int i=2;i<radius;i++)
                {
                    for (int j=1;j<i;j++)
                    {
                        buffer[bufferIndex]=tex2D(_GrabTexture,pos+float2(-i/screenSizeX,-j/screenSizeY))+tex2D(_GrabTexture,pos+float2(-i/screenSizeX,j/screenSizeY))+tex2D(_GrabTexture,pos+float2(i/screenSizeX,j/screenSizeY))+tex2D(_GrabTexture,pos+float2(i/screenSizeX,-j/screenSizeY))+
                                            tex2D(_GrabTexture,pos+float2(-j/screenSizeX,-i/screenSizeY))+tex2D(_GrabTexture,pos+float2(-j/screenSizeX,i/screenSizeY))+tex2D(_GrabTexture,pos+float2(j/screenSizeX,i/screenSizeY))+tex2D(_GrabTexture,pos+float2(j/screenSizeX,-i/screenSizeY));
                        bufferIndex++;
                    };
                };
                for (int i1=1;i1<radius;i1++)
                    {
                        buffer[bufferIndex]=tex2D(_GrabTexture,pos+float2(-i1/screenSizeX,-i1/screenSizeY))+tex2D(_GrabTexture,pos+float2(-i1/screenSizeX,i1/screenSizeY))+tex2D(_GrabTexture,pos+float2(i1/screenSizeX,i1/screenSizeY))+tex2D(_GrabTexture,pos+float2(i1/screenSizeX,-i1/screenSizeY));
                        bufferIndex++;
                    }
                    
                    
                for (int i2=1;i2<radius;i2++)
                    {
                        buffer[bufferIndex]=tex2D(_GrabTexture,pos+float2(0,-i2/screenSizeY))+tex2D(_GrabTexture,pos+float2(0,i2/screenSizeY))+tex2D(_GrabTexture,pos+float2(-i2/screenSizeX,0))+tex2D(_GrabTexture,pos+float2(i2/screenSizeX,0));
                        bufferIndex++;
                    }
                buffer[bufferIndex]=tex2D(_GrabTexture,pos);
                
                return  0.014648*buffer[0]
                + 0.001445 * buffer[1]
                + 0.000362 * buffer[2]
                + 0.000055 * buffer[3]
                + 0.000014 * buffer[4]
                + 0.000001 * buffer[5]
                + 0.058434 * buffer[6]
                + 0.003672 * buffer[7]
                + 0.000036 * buffer[8]
                + 0.092566 * buffer[10]
                + 0.023205 * buffer[11]
                + 0.002289 * buffer[12]
                + 0.000088 * buffer[13]
                + 0.146634 * buffer[14];
                
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                //float4 grabScreenPos = m_ComputeGrabScreenPos( float4(IN.texcoord.xy,0,1) );
                fixed4 color=tex2D(_MainTex, IN.texcoord)* IN.color;
                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a-0.001);
                #endif
                
                float4 grabScreenPos = m_ComputeGrabScreenPos( float4(IN.vertex.x/_ScreenParams.x,IN.vertex.y/_ScreenParams.y,0,1) );
			    float4 grabScreenPosNorm = grabScreenPos / grabScreenPos.w;
                color = fixed4(lerp( GaussianBlur(float2(grabScreenPos.x, grabScreenPos.y)),color,color.a).rgb,1) ;
                //return fixed4((GaussianBlur(float2(grabScreenPos.x, grabScreenPos.y)).rgb ) ,1);
                //return tex2D(_MainTex,IN.vertex.xy);
                return color;
            }
        ENDCG
        }
    }
}