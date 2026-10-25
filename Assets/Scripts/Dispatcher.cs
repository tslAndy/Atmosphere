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
    public int maxSteps;

    [Header("LUT params")]
    [Tooltip("X - angle division, Y - radius division")]
    public Vector2Int lutResolution;

    [Header("Components")]
    public Camera cam;
    public Material atmoMat;
    public Material lutMat;

    private RenderTexture lutTexture;

    void Start()
    {
        InitLUT();
        InitAtmo();
    }

    void InitLUT()
    {
        lutTexture = new RenderTexture(lutResolution.x, lutResolution.y, 0)
        {
            enableRandomWrite = true,
        };
        lutTexture.Create();

        lutMat.SetVector("_sunDir", sunDir.normalized);
        lutMat.SetFloat("_sunLight", sunLight);

        lutMat.SetFloat("_innerRadius", innerRadius);
        lutMat.SetFloat("_outerRadius", outerRadius);

        lutMat.SetFloat("_baseDensity", baseDensity);
        lutMat.SetFloat("_densityFalloff", densityFalloff);

        lutMat.SetVector("_waveLens", waveLens);
        lutMat.SetFloat("_baseWaveLen", baseWaveLen);

        lutMat.SetFloat("_stepSize", stepSize);
        lutMat.SetFloat("_maxSteps", maxSteps);

        Graphics.Blit(null, lutTexture, lutMat);
    }

    void Update()
    {
        Matrix4x4 invMatrix = GetInvMatrix();
        atmoMat.SetMatrix("_invMatrix", invMatrix);
    }

    void InitAtmo()
    {
        cam.depthTextureMode = DepthTextureMode.Depth;

        atmoMat.SetVector("_sunDir", sunDir.normalized);
        atmoMat.SetFloat("_sunLight", sunLight);

        atmoMat.SetVector("_planetPos", planetPos);
        atmoMat.SetFloat("_innerRadius", innerRadius);
        atmoMat.SetFloat("_outerRadius", outerRadius);

        atmoMat.SetFloat("_baseDensity", baseDensity);
        atmoMat.SetFloat("_densityFalloff", densityFalloff);

        atmoMat.SetVector("_waveLens", waveLens);
        atmoMat.SetFloat("_baseWaveLen", baseWaveLen);

        atmoMat.SetFloat("_stepSize", stepSize);
        atmoMat.SetFloat("_maxSteps", maxSteps);

        atmoMat.SetTexture("_lutTexture", lutTexture);
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
        Graphics.Blit(source, dest, atmoMat);
    }

    void OnDrawGizmos()
    {
        Gizmos.DrawLine(planetPos, planetPos + sunDir * 10);
        Gizmos.DrawWireSphere(planetPos, innerRadius);
        Gizmos.DrawWireSphere(planetPos, outerRadius);
    }
}
