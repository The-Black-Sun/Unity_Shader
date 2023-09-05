
//��������
Shader "Unity Shaders Book/Chapter 7/Single Texture"{
    Properties
    {
        //��ɫ
        _Color ("Color Tint", Color) = (1,1,1,1)
        //����һ��2D������������white����ȫ��
        _MainTex ("Main Tex", 2D) = "white" {}
        //���淴�䣨�߹ⷴ�䣩
        _Specular("Specular",Color)=(1,1,1,1)
        //���󣨲��ʸ߹ⷴ�����ȣ����������Ǹ�ָ����
        _Gloss ("Gloss", Range(8.0,256)) =20
    }
    SubShader
    {
       Pass{
            //����ģʽ
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            //Properties�е���������
            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _Specular;
            float _Gloss;

            //��������������st�����ź�ƽ�Ƶ���д��.xy��ŵ�������ֵ��.zw��ŵ���ƫ��ֵ
            float4 _MainTex_ST;

            //�������ṹ��
            struct a2v {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                //ģ�͵�һ����������
                float4 texcoord:TEXCOORD0;
            };

            struct v2f {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                //������������в���
                float2 uv:TEXCOORD2;
            };
       
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //_MainTex_ST.xy ������������ˣ��������ţ�����_MainTex_ST.zw��������ƫ��
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //���Ϲ��̿���ֱ�ӵ���TRANSFORM_TEX����
                // TRANSFORM_TEX(tex,name)
                // tex=>�����������꣬name=>��������
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //���
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //ʹ���������������ɫ���в���
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //������
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //������
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                //Blineģ��
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }

    }
    FallBack "Diffuse"
}
