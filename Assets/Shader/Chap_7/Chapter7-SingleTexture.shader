
//单张纹理
Shader "Unity Shaders Book/Chapter 7/Single Texture"{
    Properties
    {
        //颜色
        _Color ("Color Tint", Color) = (1,1,1,1)
        //声明一个2D纹理，内置纹理“white”，全白
        _MainTex ("Main Tex", 2D) = "white" {}
        //镜面反射（高光反射）
        _Specular("Specular",Color)=(1,1,1,1)
        //光泽（材质高光反射光泽度，计算后面的那个指数）
        _Gloss ("Gloss", Range(8.0,256)) =20
    }
    SubShader
    {
       Pass{
            //光照模式
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            //Properties中的属性描述
            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _Specular;
            float _Gloss;

            //纹理属性描述，st是缩放和平移的缩写，.xy存放的是缩放值，.zw存放的是偏移值
            float4 _MainTex_ST;

            //输出输入结构体
            struct a2v {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                //模型第一组纹理坐标
                float4 texcoord:TEXCOORD0;
            };

            struct v2f {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                //对纹理坐标进行采样
                float2 uv:TEXCOORD2;
            };
       
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //_MainTex_ST.xy 与纹理坐标相乘，进行缩放，加上_MainTex_ST.zw进行纹理偏移
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //以上过程可以直接调用TRANSFORM_TEX函数
                // TRANSFORM_TEX(tex,name)
                // tex=>顶点纹理坐标，name=>纹理名称
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //输出
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //使用纹理对漫反射颜色进行采样
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                //Bline模型
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
