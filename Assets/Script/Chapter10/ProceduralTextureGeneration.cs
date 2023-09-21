using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//支持脚本在编辑器模式下运行
[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour {

	//声明材质，这个材质会只用这个脚本生成的材质纹理
	public Material material = null;

	//声明程序纹理使用的各种参数
	#region Material properties
	//纹理大小
	[SerializeField, SetProperty("textureWidth")]
	private int m_textureWidth = 512;
	public int textureWidth {
		get {
			return m_textureWidth;
		}
		set {
			m_textureWidth = value;
			//开源插件，属性修改，更新纹理显示
			_UpdateMaterial();
		}
	}

	//纹理的背景颜色
	[SerializeField, SetProperty("backgroundColor")]
	private Color m_backgroundColor = Color.white;
	public Color backgroundColor {
		get {
			return m_backgroundColor;
		}
		set {
			m_backgroundColor = value;
			_UpdateMaterial();
		}
	}

	//圆点的颜色
	[SerializeField, SetProperty("circleColor")]
	private Color m_circleColor = Color.yellow;
	public Color circleColor {
		get {
			return m_circleColor;
		}
		set {
			m_circleColor = value;
			_UpdateMaterial();
		}
	}

	//模糊因子
	[SerializeField, SetProperty("blurFactor")]
	private float m_blurFactor = 2.0f;
	public float blurFactor {
		get {
			return m_blurFactor;
		}
		set {
			m_blurFactor = value;
			_UpdateMaterial();
		}
	}
	#endregion

	//保存生成的程序纹理所声明的一个Texture2D类型的纹理变量
	private Texture2D m_generatedTexture = null;

	// 获取当前物体的渲染器以及其中的材质
	void Start () {
		if (material == null) {
			Renderer renderer = gameObject.GetComponent<Renderer>();
			if (renderer == null) {
				Debug.LogWarning("Cannot find a renderer.");
				return;
			}

			material = renderer.sharedMaterial;
		}

		//通过该函数来进行材质纹理生成
		_UpdateMaterial();
	}

	//生成与更新材质纹理
	private void _UpdateMaterial() {
		if (material != null) {
			//材质不为空，调用_GenerateProceduralTexture生成程序纹理
			m_generatedTexture = _GenerateProceduralTexture();
			//将生成的纹理赋给材质_MainTex
			material.SetTexture("_MainTex", m_generatedTexture);
		}
	}

	private Color _MixColor(Color color0, Color color1, float mixFactor) {
		Color mixColor = Color.white;
		mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
		mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
		mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
		mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
		return mixColor;
	}

	private Texture2D _GenerateProceduralTexture() {
		//生成大小为textureWidth的纹理
		Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

		//定义圆之间的间距
		float circleInterval = textureWidth / 4.0f;
		//定义圆的半径
		float radius = textureWidth / 10.0f;
		//定义模糊系数
		float edgeBlur = 1.0f / blurFactor;

		for (int w = 0; w < textureWidth; w++) {
			for (int h = 0; h < textureWidth; h++) {
				//初始化像素背景颜色
				Color pixel = backgroundColor;

				//绘制一个个圆
				for (int i = 0; i < 3; i++) {
					for (int j = 0; j < 3; j++) {
						//设置圆心的位置
						Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

						//计算当前像素与圆心之间的距离
						float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

						//模糊圆的边界
						Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

						//与之前得到的颜色进行混合
						pixel = _MixColor(pixel, color, color.a);
					}
				}
				//设置像素的颜色
				proceduralTexture.SetPixel(w, h, pixel);
			}
		}

		//强制将像素写进纹理中
		proceduralTexture.Apply();

		return proceduralTexture;
	}
}
