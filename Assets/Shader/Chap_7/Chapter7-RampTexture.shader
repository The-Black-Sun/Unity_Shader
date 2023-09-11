// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//渐变纹理
Shader "Unity Shaders Book/Chapter 7/Ramp Texture" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//渐变纹理
		_RampTex ("Ramp Tex", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			
			fixed4 _Color;

			//定义渐变纹理与渐变纹理缩放平移
			sampler2D _RampTex;
			float4 _RampTex_ST;

			fixed4 _Specular;
			float _Gloss;
			
			//顶点着色器数据输入
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//第一组纹理（输入的纹理）
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				//投影空间顶点
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				//TRANSFORM_TEX,计算平铺与平移之后的纹理坐标
				o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				//获得世界空间光源
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// 半兰伯特模型（控制显示范围）
				fixed halfLambert  = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
				//获取漫反射颜色（通过纹理获取）
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
				
				//_LightColor0顶点光源强度与漫反射强度得到漫反射效果
				fixed3 diffuse = _LightColor0.rgb * diffuseColor;
				
				//高光反射，blinn模型
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
