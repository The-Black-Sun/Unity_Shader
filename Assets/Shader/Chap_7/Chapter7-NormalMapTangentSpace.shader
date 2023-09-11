Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//����
		_MainTex ("Main Tex", 2D) = "white" {}
		//��������bump�������÷�������
		_BumpMap ("Normal Map", 2D) = "bump" {}
		//��������͹���̶ȣ����ߣ���Ϊ0ʱ�����߲��Թ�������κ�Ӱ��
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
			
			//��������
			fixed4 _Color;

			//������������������ƫ��
			sampler2D _MainTex;
			float4 _MainTex_ST;
			//���������뷨����������ƫ��
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			//��������͹���̶ȣ����ߣ���Ϊ0ʱ�����߲��Թ�������κ�Ӱ��
			float _BumpScale;

			fixed4 _Specular;
			float _Gloss;
			
			//����ռ��Ƕ��㷨�ߣ���֪�������߹������Ŀռ䣬������Ҫ��ȡ���߷���
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//���߷���
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			//��Ҫ�ڶ�����ɫ���м������߿ռ�Ĺ������ӽ�
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				//�����洢���߿ռ�Ĺ�Դ���ӽ�
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//uv��xy�����洢��һ������_MainTex����������
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//uv��zw�����洢��������_BumpMap����������
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				//������
				float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
				//��ģ�Ϳռ�����߷��򡢸����߷����뷨�߷���������,�õ�ģ�Ϳռ�=>���߿ռ�ı任����
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
				//unity���÷�����ֱ�Ӽ���ģ�Ϳռ�=>���߿ռ�ı任����,�洢��rotation
				//TANGENT_SPACE_ROTATION;
				
				//��ȡ���߿ռ�Ĺ�Դ
				o.lightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
				//��ȡ���߿ռ���ӽ�
				o.viewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//���߿ռ�Ĺ�Դ�������ӽǷ���ʸ����һ��
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				
				//���з����������
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				//��������洢���Ƿ��߾���ӳ��֮�������ֵ����Ҫ���䷴ӳ�����
				// ���unity��û�����÷�������ΪNormal map���ͣ�����Ҫ�ڴ����н��з�ӳ��
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				//unity���÷���
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				//���߿ռ�ķ���z��������xy�������
				//saturate����������ֵ��Χ��[0,1]��
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				//ʹ���������������ɫ���в���
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				//������
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				//������
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//�߹ⷴ�䣬blinnģ��
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
