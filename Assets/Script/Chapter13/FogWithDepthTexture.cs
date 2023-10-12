using UnityEngine;
using System.Collections;

public class FogWithDepthTexture : PostEffectsBase {

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material {  
		get {
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}

	//获取摄像机，用来获取深度纹理
	private Camera myCamera;
	public Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	//获取摄像机位置，用来重建世界坐标
	private Transform myCameraTransform;
	public Transform cameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = camera.transform;
			}

			return myCameraTransform;
		}
	}

	//雾化程度
	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f;

	//雾化颜色
	public Color fogColor = Color.white;

	//雾化开始与结束距离，这里是居于高度的雾化效果，所以是基于高度
	public float fogStart = 0.0f;
	public float fogEnd = 2.0f;

	//获取摄像机深度纹理
	void OnEnable() {
		camera.depthTextureMode |= DepthTextureMode.Depth;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//设置默认矩阵，用来存储摄像机近剪裁平面四个向量
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			//镜头范围，镜头角
			float fov = camera.fieldOfView;
			//近剪裁平面距离
			float near = camera.nearClipPlane;
			//宽高比
			float aspect = camera.aspect;

			//计算近剪裁平面所需要的四边向量的辅助向量toRight与toTop
			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;

			//计算四角向量
			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			//通过模长度与近剪裁平面距离获得近似的缩放比，用来计算四角向量
			float scale = topLeft.magnitude / near;
			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			//设置四角向量矩阵
			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			//设置Shader获得的属性值
			//近剪裁平面的四个角对应的向量，存储在矩阵中
			material.SetMatrix("_FrustumCornersRay", frustumCorners);

			//雾效的程度，颜色，高度起止
			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
