// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		//河流纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		//控制整体颜色
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//控制水流波动幅度
		_Magnitude ("Distortion Magnitude", Float) = 1
		//控制波动频率
 		_Frequency ("Distortion Frequency", Float) = 1
		//控制波长的倒数
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
		//控制河流纹理的移动速度
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {
		// DisableBatching指明是否取消对该shader使用批处理
		// 需要特殊处理的Shader通常是包含了模型空间的顶点动画的shader，批处理会合并所有相关的模型，导致模型各自的模型空间丢失
		// 需要在物体的模型空间下独一顶点进行偏移，所以这里取消批处理操作。
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			//关闭深度写入，开启设置混合模式，关闭剔除功能
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			
			#include "UnityCG.cginc" 
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			//顶点着色器设置顶点动画
			v2f vert(a2v v) {
				v2f o;
				
				//计算顶点位移量，只对顶点x方向进行位移
				float4 offset;
				//yzw的位移量设置为0
				offset.yzw = float3(0.0, 0.0, 0.0);
				//设置x的位移量
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				//获得变换后的顶点位置
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);
				
				return o;
			}
			
			//片元着色器对纹理进行采样并进行颜色控制
			fixed4 frag(v2f i) : SV_Target {
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
