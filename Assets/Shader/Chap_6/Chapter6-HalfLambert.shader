// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Half Lambert" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;

				// 将顶点坐标从模型空间转换到投影空间
				o.pos = UnityObjectToClipPos(v.vertex);

				// 将顶点法线，从模型空间转换到世界空间
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//获取环境光数据
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//获取世界空间的顶点法线，并归一化
				fixed3 worldNormal = normalize(i.worldNormal);

				//获取世界空间的光源归一化矢量
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				//进行漫反射模型计算
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

				//合并环境光与漫反射光线
				fixed3 color = ambient + diffuse;

				return fixed4(color, 1.0);
				
			}
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
