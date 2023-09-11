//凹凸，世界空间——法线纹理
Shader "Unity Shaders Book/Chapter 7/Normal Map In World Space" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//贴图与法线贴图以及法线凹凸系数
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1.0

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

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;

			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				//注意这里计算的是世界空间的凹凸纹理
				//这里是存储了切线空间到世界空间的转换矩阵
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//对纹理坐标进行缩放与平移
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				//世界空间顶点
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				//世界空间法线
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				//世界空间切线
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				//世界空间副切线
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				// 摆放世界空间法线，世界空间切线，世界空间副切线得到切线空间到设计空间的变换矩阵
				// 保存世界空间顶点xyz（利用存储空间，保存世界空间坐标）
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// 获取世界空间顶点坐标	
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// 获取世界空间光源与视角
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// 使用UnpackNormal进行法线贴图采样与解码（将法线纹理标格式识成Normal map）
				//法线纹理标记成Normal map的时候，能够通过UnpackNormal获得正确的法线方向
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				//通过_BumpScale对法线进行缩放
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				//将法线从切线空间转换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				
				//纹理材质采样
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
