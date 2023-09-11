// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//遮罩纹理
Shader "Unity Shaders Book/Chapter 7/Mask Texture" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//主纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		//法线纹理与法线凹凸缩放
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		//遮罩纹理与遮罩缩放
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		_SpecularScale ("Specular Scale", Float) = 1.0

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
			//主纹理与纹理缩放
			sampler2D _MainTex;
			float4 _MainTex_ST;
			//法线纹理与纹理缩放
			sampler2D _BumpMap;
			float _BumpScale;
			//遮罩纹理与缩放（是用来控制高光反射效果的）
			sampler2D _SpecularMask;
			float _SpecularScale;

			fixed4 _Specular;
			float _Gloss;
			
			//顶点着色器输入：模型空间顶点、法线、切线、第一张纹理
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			//顶点输出与片元着色器输入：顶点位置、uv纹理、光源、视角
			struct v2f {
				//剪裁空间
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				//切线空间
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};
			
			//顶点着色器
			v2f vert(a2v v) {
				v2f o;
				//模型空间顶点=>剪裁空间顶点
				o.pos = UnityObjectToClipPos(v.vertex);
				//对第一张纹理进行采样（缩放平移）
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				
				//unity内置方法，直接计算模型空间=>切线空间的变换矩阵,存储到rotation
				TANGENT_SPACE_ROTATION;
				//获得切线空间的光源与视角
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//切线空间光源视角归一化
			 	fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//获得切线空间法线，纹理采样与解码
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				//主纹理材质采样
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				
				//blinn模型，视角与入射光源的平分线
			 	fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			 	
				//遮罩纹理采样（本纹理，三个通道数值相同步，rgb三个通道只使用了r通道）
			 	fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
			 	
				//高光反射——高光反射结果乘以遮罩纹理采样数据
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;
			
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
