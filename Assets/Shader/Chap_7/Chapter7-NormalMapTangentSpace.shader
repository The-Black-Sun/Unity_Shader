Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		//法线纹理“bump”是内置法线纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}
		//用来控制凸凹程度（法线），为0时，法线不对光照造成任何影响
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
			
			//属性描述
			fixed4 _Color;

			//主纹理与主纹理缩放偏移
			sampler2D _MainTex;
			float4 _MainTex_ST;
			//法线纹理与法线纹理缩放偏移
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			//用来控制凸凹程度（法线），为0时，法线不对光照造成任何影响
			float _BumpScale;

			fixed4 _Specular;
			float _Gloss;
			
			//顶点空间是顶点法线（已知）与切线构建出的空间，这里需要获取切线方向
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//切线方向
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			//需要在顶点着色器中计算切线空间的光照与视角
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				//用来存储切线空间的光源与视角
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//uv的xy分量存储第一张纹理_MainTex的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//uv的zw分量存储法线纹理_BumpMap的纹理坐标
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				//副切线
				float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
				//将模型空间的切线方向、副切线方向与法线方向安行排列,得到模型空间=>切线空间的变换矩阵
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
				//unity内置方法，直接计算模型空间=>切线空间的变换矩阵,存储到rotation
				//TANGENT_SPACE_ROTATION;
				
				//获取切线空间的光源
				o.lightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
				//获取切线空间的视角
				o.viewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//切线空间的光源方向与视角方向矢量归一化
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				
				//进行法线纹理采样
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				//法线纹理存储的是法线经过映射之后的像素值。需要将其反映射回来
				// 如果unity中没有设置法线纹理为Normal map类型，就需要在代码中进行反映射
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				//unity内置方法
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				//切线空间的法线z分量，由xy分量获得
				//saturate函数限制数值范围在[0,1]中
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				//使用纹理对漫反射颜色进行采样
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//高光反射，blinn模型
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
