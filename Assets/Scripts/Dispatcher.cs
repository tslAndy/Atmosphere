using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dispatcher : MonoBehaviour
{
    [Header("Sun Params")]
    public Vector3 sunDir;
    public float sunLight;

    [Header("Planet Params")]
    public Vector3 planetPos;
    public float innerRadius,
        outerRadius; // atmosphere inner and outer radius

    [Header("Atmosphere params")]
    public float baseDensity;
    public float densityFalloff;

    public float baseWaveLen;
    public Vector3 waveLens;

    [Header("Performance params")]
    public float stepSize;

    [Header("Components")]
    public Camera cam;
    public Material mat;

    void Start()
    {
        cam.depthTextureMode = DepthTextureMode.Depth;
    }

    void Update()
    {
        Matrix4x4 invMatrix = GetInvMatrix();
        mat.SetMatrix("_invMatrix", invMatrix);

        mat.SetVector("_sunDir", sunDir.normalized);
        mat.SetFloat("_sunLight", sunLight);

        mat.SetVector("_planetPos", planetPos);
        mat.SetFloat("_innerRadius", innerRadius);
        mat.SetFloat("_outerRadius", outerRadius);

        mat.SetFloat("_baseDensity", baseDensity);
        mat.SetFloat("_densityFalloff", densityFalloff);

        mat.SetVector("_waveLens", waveLens);
        mat.SetFloat("_baseWaveLen", baseWaveLen);

        mat.SetFloat("_stepSize", stepSize);
    }

    Matrix4x4 GetInvMatrix()
    {
        Matrix4x4 invNDC = new Matrix4x4
        {
            m00 = 2.0f,
            m11 = 2.0f,
            m03 = -1.0f,
            m13 = -1.0f,
            m22 = 1.0f,
            m33 = 1.0f,
        };

        Matrix4x4 camToWorld = cam.cameraToWorldMatrix;
        // remove translation
        camToWorld.m03 = 0.0f;
        camToWorld.m13 = 0.0f;
        camToWorld.m23 = 0.0f;

        Matrix4x4 projInverse = cam.projectionMatrix.inverse;

        return camToWorld * projInverse * invNDC;
    }

    void OnRenderImage(RenderTexture source, RenderTexture dest)
    {
        Graphics.Blit(source, dest, mat);
    }

    void OnDrawGizmos()
    {
        Gizmos.DrawWireSphere(planetPos, innerRadius);
        Gizmos.DrawWireSphere(planetPos, outerRadius);
    }
}
