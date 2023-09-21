// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Scrolling Background" {
	Properties {
		//主（基础）纹理，这里背景分成两层
		_MainTex ("Base Layer (RGB)", 2D) = "white" {}
		//背景纹理
		_DetailTex ("2nd Layer (RGB)", 2D) = "white" {}
		//2张纹理的水平滚动速度
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0
		//_Multipliter 用于控制纹理的整体亮度
		_Multiplier ("Layer Multiplier", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
			
			//顶点着色器
			v2f vert (a2v v) {
				v2f o;
				//顶点从模型空间变换到剪裁空间中
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//计算两层背景纹理的纹理坐标
				//先通过TRANSFORM_TEX获取初始纹理坐标，在通过_Time.y进行水平上的偏移
				//纹理坐标存储在同一个变量o.uv中
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				//对两张纹理进行采样
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				//通过CG的Lerp函数来使用第二层纹理的透明通道混合2张纹理
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				//使用纹理整体亮度和输出颜色相乘，调整背景亮度
				c.rgb *= _Multiplier;
				
				return c;
			}
			
			ENDCG
		}
	}
	FallBack "VertexLit"
}
